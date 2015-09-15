# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

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
    require "fileutils"
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

  class << self
    def parse(file)
      name = report_name file

      dates = name.scan(/\d{4}-\d{2}-\d{2}_\d{2}:\d{2}/)
      from_time_ = dates.length > 0 ? DateTime.parse("#{dates[0]} #{Time.zone}") : file.ctime.to_datetime
      to_time_ = dates.length > 1 ? DateTime.parse("#{dates[1]} #{Time.zone}") : from_time_

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

  class Generate < Tableless
    attr_accessor :from_time
    attr_accessor :to_time

    validate do |record|
      begin
        DateTime.parse record.from_time
      rescue ArgumentError
        errors.add(:from_time, _("must be a valid datetime"))
      end

      begin
        DateTime.parse record.to_time
      rescue ArgumentError
        errors.add(:to_time, _("must be a valid datetime"))
      end
    end

    def new_record?
      false
    end

    def persisted?
      false
    end

    def from_time
      DateTime.parse(@from_time).strftime("%Y-%m-%d %H:%M")
    end

    def to_time
      DateTime.parse(@to_time).strftime("%Y-%m-%d %H:%M")
    end

    def name
      ft = DateTime.parse(@from_time).strftime("%Y-%m-%d %H:%M")
      tt = DateTime.parse(@to_time).strftime("%Y-%m-%d %H:%M")
      fs = from_time.sub(' ', '_')
      ts = to_time.sub(' ', '_')
      "hb_report-hawk-#{fs}-#{ts}"
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
