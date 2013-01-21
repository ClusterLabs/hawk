#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., All Rights Reserved.
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
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#======================================================================

# Necessary for Time.parse in Ruby 1.8 (should be unnecessary in 1.9)
require "time"
require "natcmp"

class ExplorerController < ApplicationController
  before_filter :login_required, :ensure_godlike, :init_params

  layout 'main'

  @@x_path = "#{Rails.root}/tmp/explorer"

  def initialize
    super
    @title = _('History Explorer')
    @errors = []
    @hb_report = HbReport.new("#{Rails.root}/tmp/pids/history_report")
  end

  def index
    @cache = []

    ts_re = "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}"
    Dir.entries(@@x_path).sort.reverse.each do |f|
      m = f.match(/^hb_report-hawk-(#{ts_re})-(#{ts_re}).tar.bz2$/)
      next unless m
      @cache << {
        :from_time => m[1].sub("_", " "),
        :to_time =>   m[2].sub("_", " "),
      }
    end

    if params[:delete]
      require "fileutils"
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
      if File.exists?(@report_path)
        @peinputs = []
        stdin, stdout, stderr, thread = Util.run_as("root", "crm", "history")
        stdin.write("source #{@report_path}\npeinputs\n")
        stdin.close
        peinputs_raw = stdout.read()
        stdout.close
        err = stderr.read()
        stderr.close
        if thread.value.exitstatus == 0
          peinputs_raw.split(/\n/).each do |path|
            next unless File.exists?(path)
            @peinputs << {
              :timestamp => File.mtime(path).strftime("%Y-%m-%d %H:%M:%S"),
              :basename  => File.basename(path, ".bz2"),
              :node      => path.split(File::SEPARATOR)[-3]
            }
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

  # Remarkably similar to MainController::sim_get
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
    tpath = "#{@@x_path}/#{@report_name}/#{tname}"
    case params[:file]
    when "pe-input"
      send_file tpath, :type => "application/x-bzip"
    when "info"
      stdin, stdout, stderr, thread = Util.run_as("root", "crm", "history")
      stdin.write("source #{@report_path}\ntransition #{tname} nograph\n")
      stdin.close
      info = stdout.read()
      stdout.close
      info += stderr.read()
      stderr.close

      info.strip!
      # TODO(should): option to increase verbosity level
      info = _("No details available") if info.empty?

      info.insert(0, _("Error:") + "\n") unless thread.value.exitstatus == 0

      send_data info, :type => "text/plain", :disposition => "inline"
    when "graph"
      # Apparently we can't rely on the dot file existing in the hb_report, so we
      # just use ptest to generate it.  Note that this will fail if hacluster doesn't
      # have read access to the pengine files (although, this should be OK, because
      # they're created by hacluster by default).
      require "tempfile"
      tmpfile = Tempfile.new("hawk_dot")
      tmpfile.close
      Util.safe_x("/usr/sbin/ptest", "-x", tpath,
        params[:format] == "xml" ? "-G" : "-D", tmpfile.path)
      # TODO(must): handle failure of above

      if params[:format] == "xml"
        # Can't use send_file here, server whines about file not existing(?!?)
        send_data File.new(tmpfile.path).read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
      else
        stdin, stdout, stderr, thread = Util.popen3("/usr/bin/dot", "-Tpng", tmpfile.path)
        stdin.close
        png = stdout.read
        stdout.close
        err = stderr.read
        stderr.close
        if thread.value.exitstatus == 0
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

  private

  # TODO(should): Dupe from HbReportsController - consolidate
  def ensure_godlike
    unless is_god?
      render :permission_denied
    end
  end

  def init_params
    lasttime = @hb_report.lasttime
    if @hb_report.running? && lasttime 
      # If we're already running, use the last run time & date
      @from_time, @to_time = lasttime
    else
      # Start 24 hours ago by default
      @from_time = params[:from_time] ? Time.parse(params[:from_time]) : Time.now - 86400
      @to_time = params[:to_time] ? Time.parse(params[:to_time]) : Time.now
      
      # Ensure from_time is earlier than to_time.  Should probably make sure they're
      # not idendical (kind of pointless doing a zero minute hb_report...)
      @from_time, @to_time = @to_time, @from_time if @from_time > @to_time
      
      # ...and now back to a string
      @from_time = @from_time.strftime("%Y-%m-%d %H:%M")
      @to_time = @to_time.strftime("%Y-%m-%d %H:%M")
    end

    @report_name = "hb_report-hawk-#{@from_time.sub(' ','_')}-#{@to_time.sub(' ','_')}"
    @report_path = "#{@@x_path}/#{@report_name}.tar.bz2"

    @hb_report.path = "#{@@x_path}/#{@report_name}"
  end

end
