#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

class ExplorerController < ApplicationController
  before_filter :login_required, :ensure_godlike, :init_params

  def initialize
    super
    @title = _('History Explorer')
    @errors = []
    @hb_report = HbReport.new("#{Rails.root}/tmp/pids/history_report")
  end

  def index
    @cache = []

    ts_re = "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}"
    explorer_path.entries.sort.reverse.each do |f|
      m = f.basename.to_s.match(/^hb_report-hawk-(#{ts_re})-(#{ts_re}).tar.bz2$/)
      next unless m
      @cache << {
        :from_time => m[1].sub("_", " "),
        :to_time =>   m[2].sub("_", " "),
      }
    end

    if params[:delete]
      require "fileutils"
      # TODO(must): won't work with uploads
      FileUtils.remove_entry_secure(@report_path) if File.exists?(@report_path)
      FileUtils.remove_entry_secure(@hb_report.path) if File.exists?(@hb_report.path)
      FileUtils.remove_entry_secure(@hb_report.outfile) if File.exists?(@hb_report.outfile)
      FileUtils.remove_entry_secure(@hb_report.errfile) if File.exists?(@hb_report.errfile)
      redirect_to :action => "index"
      return
    end

    if params[:display] && !@hb_report.running?
      # Now we either generate if a report for that time doesn't exist, or display if one does.
      # TODO(must): this doesn't handle the case where a generate run fails utterly; it'll
      # probably just keep trying to generate the hb_report indefinitely.
      pcmk_version = nil
      m = %x[cibadmin -!].match(/^Pacemaker ([^ ]+) \(Build: ([^)]+)\)/)
      pcmk_version = "#{m[1]}-#{m[2]}" if m
      if File.exists?(@report_path)
        # Have to blow this away if it exists (i.e. is a cached report), else
        # prior cibadmin calls on individual PE inputs will have wrecked their mtimes.
        FileUtils.remove_entry_secure(@hb_report.path) if File.exists?(@hb_report.path)
        @peinputs = []
        peinputs_raw, err, status = Util.capture3("crm", "history", :stdin_data => "source #{@report_path}\npeinputs\n")
        if status.exitstatus == 0
          peinputs_raw.split(/\n/).each do |path|
            next unless File.exists?(path)
            @peinputs << {
              :timestamp => File.mtime(path).strftime("%Y-%m-%d %H:%M:%S"),
              :basename  => File.basename(path, ".bz2"),
              :filename  => File.basename(path),
              :path      => path.sub("#{explorer_path.to_s}/", ''),  # only use relative portion
              :node      => path.split(File::SEPARATOR)[-3]
            }
            v = peinput_version(path)
            @peinputs[-1][:info] = v == pcmk_version ? nil : (v ?
              _("PE Input created by different Pacemaker version (%{version})" % { :version => v }) :
              _("Pacemaker version not present in PE Input"))
          end
          # sort is going to be off for identical mtimes (stripped back to the second),
          # so need secondary sort by filename
        end
        # exitstatus will be 1 if (somehow) there's no peinputs, but this shouldn't
        # be reported as an error.
        @errors += @hb_report.err_filtered
        err.split(/\n/).each do |e|
          @errors << e
        end
      elsif params[:refresh]
        # This is a "refresh" request, thus we're trying to get updated status
        # from an existing run, except hb_report is not running and there's no
        # report file, thus something died horribly.
        # TODO(should): This whole sequence might still be a little fragile: re-evaluate.
        @peinputs = []   # neccessary for correct display to trigger
        @errors += @hb_report.err_filtered
      else
        @hb_report.generate(@from_time, true, @to_time)
      end
    end
  end

  # Remarkably similar to MainController::sim_get (kinda)
  # Note reliance on hb_report directory strucutre - if that ever changes, code
  # here will need to change too.
  def get
    unless params[:basename] && params[:node]
      render :status => 400, :content_type => "text/plain",
        :inline => _('Required parameters "basename" and "node" not specified')
      return
    end
    # next two are a bit rough
    params[:basename].gsub!(/[^\w-]/, "")
    params[:node].gsub!(/[^\w_-]/, "")
    tname = "#{params[:node]}/pengine/#{params[:basename]}.bz2"
    params[:path].gsub!("..", "") # tear out possible relative junk
    tpath = explorer_path.join(params[:path]).to_s
    case params[:file]
    when "pe-input"
      send_file tpath, :type => "application/x-bzip"
    when "info"
      cmd = "transition #{tname} nograph"
      cmd = "transition log #{tname}" if params[:log]
      out, err, status = Util.run_as("root", "crm", "history", :stdin_data => "source #{@report_path}\n#{cmd}\n")
      info = out + err

      info.strip!
      # TODO(should): option to increase verbosity level
      info = _("No details available") if info.empty?

      info.insert(0, _("Error:") + "\n") unless status.exitstatus == 0

      send_data info, :type => "text/plain", :disposition => "inline"
    when "graph"
      # Apparently we can't rely on the dot file existing in the hb_report, so we
      # just use ptest to generate it.  Note that this will fail if hacluster doesn't
      # have read access to the pengine files (although, this should be OK, because
      # they're created by hacluster by default).
      require "tempfile"
      tmpfile = Tempfile.new("hawk_dot")
      tmpfile.close
      Util.safe_x("/usr/sbin/crm_simulate", "-x", tpath,
        params[:format] == "xml" ? "-G" : "-D", tmpfile.path)
      # TODO(must): handle failure of above

      if params[:format] == "xml"
        # Can't use send_file here, server whines about file not existing(?!?)
        send_data File.new(tmpfile.path).read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
      else
        png, err, status = Util.capture3("/usr/bin/dot", "-Tpng", tmpfile.path)
        if status.exitstatus == 0
          send_data png, :type => "image/png", :disposition => "inline"
        else
          render :status => 500, :content_type => "text/plain", :inline => _("Error:") + "\n#{err}"
        end
      end

      tmpfile.unlink
    else
      head :not_found
    end
  end

  def diff
    unless params[:left] && params[:right]
      render :status => 400, :content_type => "text/plain",
        :inline => _('Required parameters "left" and "right" not specified')
      return
    end

    # l and r are filenames
    l = params[:left]
    r = params[:right]

    # Allows html inline into dialog or plain text if link opened in new window
    format = params[:format] == "html" ? "html" : ""

    if (l && r)
      out, err, status = Util.run_as("root", "crm", "history", :stdin_data => "source #{@report_path}\ndiff #{l} #{r} status #{format}\ndiff #{l} #{r} #{format}\n")
      info = out + err

      info.strip!
      # TODO(should): option to increase verbosity level
      info = _("No details available") if info.empty?

      if status.exitstatus == 0
        if format == "html"
          info += <<-eos
            <table>
              <tr>
                <th>#{_('Legend')}:</th>
                <td class="diff_add">#{_('Added')}</th>
                <td class="diff_chg">#{_('Changed')}</th>
                <td class="diff_sub">#{_('Deleted')}</th>
              </tr>
            </table>
            <script type="text/javascript">
              /* Get rid of line numbers (bnc#807503) */
              $("th.diff_header").each(function() { this.colSpan = 1; });
              $("td.diff_header").hide();
            </script>
          eos
        end
      else
        info.insert(0, _("Error:") + "\n")
      end

      send_data info, :type => (format == "html" ? "text/html" : "text/plain"), :disposition => "inline"
    else
      head :not_found
    end
  end

  private

  # TODO(should): Dupe from HbReportsController - consolidate
  def ensure_godlike
    unless is_god?
      render :permission_denied
    end
  end

  # This handles the case where some crazy thing has been entered by the user
  # (e.g.: 2014-00-00) which would ordinarily throw an exception resulting in
  # a 500 error
  def time_param(val, default)
    begin
      Time.parse(val)
    rescue
      default
    end
  end

  def init_params
    lasttime = @hb_report.lasttime
    if @hb_report.running? && lasttime
      # If we're already running, use the last run time & date
      @from_time, @to_time = lasttime
    else
      # Start 24 hours ago by default
      @from_time = time_param(params[:from_time], Time.now - 86400)
      @to_time = time_param(params[:to_time], Time.now)

      # Ensure from_time is earlier than to_time.  Should probably make sure they're
      # not idendical (kind of pointless doing a zero minute hb_report...)
      @from_time, @to_time = @to_time, @from_time if @from_time > @to_time

      # ...and now back to a string
      @from_time = @from_time.strftime("%Y-%m-%d %H:%M")
      @to_time = @to_time.strftime("%Y-%m-%d %H:%M")
    end

    if params[:uploaded_report]
      # TODO(must): handle overwriting existing files
      #             (note that hb_reports from hawk seem to all extract to hb_report-hawk, not their filename?)
      #             e.g.:bug-781207_hb_report-hawk.tar.bz2)
      # TODO(must): verify original_filename doesn't contain evil
      uploaded_io = params[:uploaded_report]
      @upload_name = uploaded_io.original_filename
      @report_path = Rails.root.join('tmp', 'explorer', 'uploads', @upload_name)
      File.open(@report_path, 'wb') do |file|
        file.write(uploaded_io.read)
      end
      # @report_name actually not really used when uploading (*ugh*)
      @report_name = "uploads/#{File.basename(@report_path, '.tar.bz2')}"
    elsif params[:upload_name]
      # TODO(must): dupe of above, kinda, fix.  Also unsafe.
      @upload_name = params[:upload_name]
      @report_path = Rails.root.join('tmp', 'explorer', 'uploads', @upload_name)
      @report_name = "uploads/#{File.basename(@report_path, '.tar.bz2')}"
    else
      @report_name = "hb_report-hawk-#{@from_time.sub(' ','_')}-#{@to_time.sub(' ','_')}"
      @report_path = explorer_path.join("#{@report_name}.tar.bz2").to_s
    end

    @hb_report.path = explorer_path.join(@report_name).to_s
  end

  def peinput_version(path)
    nvpair = %x[CIB_file=#{path} cibadmin -Q --xpath "/cib/configuration//crm_config//nvpair[@name='dc-version']" 2>/dev/null]
    m = nvpair.match(/value="([^"]+)"/)
    return nil unless m
    m[1]
  end

  def explorer_path
    @explorer_path ||= Rails.root.join("tmp", "explorer")

    unless @explorer_path.directory?
      @explorer_path.mkpath
    end

    @explorer_path
  end
end
