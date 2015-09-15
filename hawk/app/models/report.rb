# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'fileutils'

class Report
  attr_accessor :id
  attr_accessor :name
  attr_accessor :archive
  attr_accessor :from_time
  attr_accessor :to_time

  def initialize(attributes)
    attributes.each do |key, value|
      self.send("#{key}=".to_sym, value)
    end
  end

  def delete(hb_report)
    self.archive.delete
    FileUtils.remove_entry_secure(hb_report.path) if File.exists?(hb_report.path)
    FileUtils.remove_entry_secure(hb_report.outfile) if File.exists?(hb_report.outfile)
    FileUtils.remove_entry_secure(hb_report.errfile) if File.exists?(hb_report.errfile)
  end

  def load!
  end

  def report_path
    self.class.report_path
  end

  def mimetype
    if archive.extname == ".bz2"
      "application/x-bzip"
    elsif archive.extname == ".xz"
      "application/x-xz"
    elsif archive.extname == ".gz"
      "application/x-gz"
    else
      "application/x-compressed"
    end
  end

  def transitions(hb_report)
    # TODO(fix this)
    # Have to blow this away if it exists (i.e. is a cached report), else
    # prior cibadmin calls on individual PE inputs will have wrecked their mtimes.
    # FileUtils.remove_entry_secure(hb_report.path) if File.exists?(hb_report.path)

    source = archive
    source = hb_report.path if File.directory?(hb_report.path)

    pcmk_version = nil
    m = %x[cibadmin -!].match(/^Pacemaker ([^ ]+) \(Build: ([^)]+)\)/)
    pcmk_version = "#{m[1]}-#{m[2]}" if m

    [].tap do |peinputs|
      peinputs_raw, err, status = Util.capture3("crm", "history", :stdin_data => "source #{source}\npeinputs\n")
      if status.exitstatus == 0
        peinputs_raw.split(/\n/).each do |path|
          next unless File.exists?(path)
          v = peinput_version(path)
          version = v == pcmk_version ? nil : (v ?
                                                 _("PE Input created by different Pacemaker version (%{version})" % { :version => v }) :
                                                 _("Pacemaker version not present in PE Input"))
          peinputs.push(timestamp: File.mtime(path).iso8601(),
                        basename: File.basename(path, ".bz2"),
                        filename: File.basename(path),
                        path: path.sub("#{hb_report.path}/", ''),  # only use relative portion
                        node: path.split(File::SEPARATOR)[-3],
                        version: version)
        end
        # sort is going to be off for identical mtimes (stripped back to the second),
        # so need secondary sort by filename
      end

      # add errors to output
      errors = hb_report.err_filtered
      errors.each do |err|
        peinputs.push error: err
      end
    end
  end

  def peinput(path, basename, node)
    basename = basename.gsub(/[^\w-]/, "")
    node = node.gsub(/[^\w_-]/, "")
    tname = "#{node}/pengine/#{basename}.bz2"
    path = path.gsub("..", "") # tear out possible relative junk
    archive.join(path).to_s
  end

  def peinput_version(path)
    nvpair = %x[CIB_file=#{path} cibadmin -Q --xpath "/cib/configuration//crm_config//nvpair[@name='dc-version']" 2>/dev/null]
    m = nvpair.match(/value="([^"]+)"/)
    return nil unless m
    m[1]
  end

  def transition_cmd(hb_report, path, cmd)
    source = archive
    source = hb_report.path if File.directory?(hb_report.path)
    Util.capture3("crm", "history", :stdin_data => "source #{source}\n#{cmd}\n")
  end

  def info(hb_report, path)
    out, err, status = transition_cmd hb_report, path, "transition #{path} nograph"
    info = out + err
    info.strip!
    info = _("No details available") if info.empty?
    info.insert(0, _("Error:") + "\n") unless status.exitstatus == 0
    info
  end

  def tags(hb_report, path)
    out, err, status = transition_cmd hb_report, path, "transition tags #{path}"
    out.split()
  end

  def logs(hb_report, path)
    out, err, status = transition_cmd hb_report, path, "transition log #{path}"
    info = out + err
    info.strip!
    info = _("No details available") if info.empty?
    info.insert(0, _("Error:") + "\n") unless status.exitstatus == 0
    info
  end

  # Returns [success, data|error]
  def graph(hb_report, path, format=:svg)

    tpath = Pathname.new(hb_report.path).join(path)

    # Apparently we can't rely on the dot file existing in the hb_report, so we
    # just use ptest to generate it.  Note that this will fail if hacluster doesn't
    # have read access to the pengine files (although, this should be OK, because
    # they're created by hacluster by default).
    require "tempfile"
    tmpfile = Tempfile.new("hawk_dot")
    tmpfile.close
    File.chmod(0666, tmpfile.path)
    out, err, status = Util.run_as('hacluster', 'crm_simulate', '-x', tpath.to_s, format == :xml ? "-G" : "-D", tmpfile.path.to_s)
    #status = Util.safe_x("/usr/sbin/crm_simulate", "-x", tpath, format == :xml ? "-G" : "-D", tmpfile.path)
    rc = status.exitstatus

    # TODO(must): handle failure of above

    ret = [false, err]
    if rc != 0
      ret = [false, err]
    elsif format == :xml || format == :json
      # Can't use send_file here, server whines about file not existing(?!?)
      # send_data File.new(tmpfile.path).read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
      ret = [true, File.new(tmpfile.path).read]
    else
      svg, err, status = Util.capture3("/usr/bin/dot", "-Tsvg", tmpfile.path)
      if status.exitstatus == 0
        ret = [true, svg]
      else
        ret = [false, err]
      end
    end
    tmpfile.unlink
    ret
  end

  # Returns the diff as a text or html string
  def diff(hb_report, path, left, right, format=:html)
    format = "" unless format == :html
    out, err, status = transition_cmd hb_report, path, "diff #{left} #{right} status #{format}"
    info = out + err

    info.strip!
    # TODO(should): option to increase verbosity level
    info = _("No details available") if info.empty?

    if status.exitstatus == 0
      if format == :html
        info += <<-eos
          <div class="row"><div class="col-sm-2">
          <table class="table">
            <tr><th>#{_('Legend')}:</th></tr>
            <tr><td class="diff_add">#{_('Added')}</th></tr>
            <tr><td class="diff_chg">#{_('Changed')}</th></tr>
            <tr><td class="diff_sub">#{_('Deleted')}</th></tr>
          </table>
          </div></div>
        eos
      end
    else
      info.insert(0, _("Error:") + "\n")
    end
    info
  end

  class << self
    def parse(file)
      name = report_name file

      dates = name.scan(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:(?:\+\d{2}:\d{2})|Z)/)
      if dates.length == 2
        from_time_ = DateTime.parse dates[0]
        to_time_ = DateTime.parse dates[1]
      else
        from_time_ = file.ctime.to_datetime
        to_time_ = from_time_
      end

      Report.new id: report_id(name), archive: file, name: name, from_time: from_time_, to_time: to_time_
    end

    def find(id)
      file = report_file(id)

      Rails.logger.debug "Found #{file}"

      if file
        record = parse(file)
        record.load!
        record
      else
        nil
      end
    end

    def all
      report_files.values.map do |file|
        parse(file)
      end.sort_by(&:name)
    end

    def report_name(file)
      n = file
      n = n.basename(n.extname)
      n = n.basename(n.extname) if n.extname == ".tar"
      n.to_s
    end


    def report_id(name)
      Digest::SHA1.hexdigest(name)[0..8]
    end

    def report_files
      basenames = [".bz2", ".gz", ".xz"]
      files = report_path.children.select { |file| file if basenames.include? file.extname }
      {}.tap do |ret|
        files.each do |file|
          id = report_id(report_name(file))
          ret[id] = file
        end
      end
    end

    def report_file(name)
      reports = report_files
      Rails.logger.debug "Reports: #{reports}, looking for #{name}"
      reports[name]
    end

    def report_path
      @report_path ||= Rails.root.join("tmp", "reports")
      @report_path.mkpath unless @report_path.directory?
      @report_path
    end
  end

  class Upload < Tableless
    attribute :upload, ActionDispatch::Http::UploadedFile

    validate do |record|
      unless record.upload.content_type == "application/x-bzip" ||
             record.upload.content_type == "application/x-xz" ||
             record.upload.content_type == "application/x-gz"
        errors.add(:from_time, _("must have correct MIME type"))
      end

      unless record.upload.original_filename =~ /\.tar\.(bz2|gz|xz)\z/
        errors.add(:from_time, _("must have correct file extension"))
      end
    end

    def new_record?
      false
    end

    def persisted?
      true
    end

    protected

    def persist!
      path = Rails.root.join("tmp", "reports")
      path.mkpath unless path.directory?
      path = path.join(@upload.original_filename)
      FileUtils.rm path if path.file?
      FileUtils.cp @upload.tempfile.to_path, path
      Rails.logger.debug "Uploaded to #{path}"
      true
    end
  end
end
