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

  def initialize
    super
    @title = _('History Explorer')

    @pidfile = "#{RAILS_ROOT}/tmp/pids/history_report.pid"
    @outfile = "#{RAILS_ROOT}/tmp/pids/history_report.stdout"
    @errfile = "#{RAILS_ROOT}/tmp/pids/history_report.stderr"
    @exitfile = "#{RAILS_ROOT}/tmp/pids/history_report.exit"
    @timefile = "#{RAILS_ROOT}/tmp/pids/history_report.time"
  end

  def index
    if !params[:back].blank?
      redirect_to status_path
      return
    end

    if params[:display] && !File.exists?(@pidfile)
      # Now we either generate if a report for that time doesn't exist, or display if one does.
      if File.exists?(@report_path)
        @peinputs = []
        stdin, stdout, stderr, thread = Util.run_as("root", "crm", "history")
        stdin.write("source #{@report_path}\npeinputs list\n")
        stdin.close
        peinputs_raw = stdout.read()
        stdout.close
        stderr.close
        if thread.value.exitstatus == 0
          peinputs_raw.split(/\n/).each do |line|
            path = line.split(/\s+/)[-1]
            @peinputs << {
              :timestamp => File.mtime(path).strftime("%Y-%m-%d %H:%M:%S"),
              :basename  => File.basename(path, ".bz2"),
              # Node here is a bit rough (relies firmly on hb_report directory structure)
              :node      => path.split(File::SEPARATOR)[-3]
            }
          end
          # sort is going to be off for identical mtimes (stripped back to the second),
          # so need secondary sort by filename
        else
          # TODO(must): show error
        end
      else
        generate
      end
    end
  end

  # Remarkably similar to MainController::sim_get
  def get
    unless params[:basename] && params[:node]
      # strictly, missing params
      return :not_found
    end
    # next two are a bit rough
    params[:basename].gsub!(/[^\w-]/, "")
    params[:node].gsub!(/[^\w_-]/, "")
    tnum = params[:basename].split("-")[-1]
    case params[:file]
    when "pe-input"
      # nasty - reliant on hb_report structure & file extension
      send_file "/tmp/#{@report_name}/#{params[:node]}/pengine/#{params[:basename]}.bz2", :type => "application/x-bzip"
    when "info"
      stdin, stdout, stderr, thread = Util.run_as("root", "crm", "history")
      stdin.write("source #{@report_path}\ntransition show #{tnum} nograph\n")
      stdin.close
      info = stdout.read()
      stdout.close
      info += stderr.read()
      stderr.close
      if thread.value.exitstatus == 0
        send_data info, :type => "text/plain", :disposition => "inline"
      else
        # TODO(must): handle error
        head :not_found
      end
    when "graph"
      # apparently we can't rely on the dot file existing in the hb_report, so we
      # just use ptest to generate it, although, again, this is nasty as above as
      # it's reliant on hb_report structure.  Also, it'll fail if hacluster doesn't
      # have read access to the pengine files (although, this should be OK, because
      # they're created by hacluster by default).
      require "tempfile"
      tmpfile = Tempfile.new("hawk_dot")
      tmpfile.close
      Util.safe_x("/usr/sbin/ptest",
        "-x", "/tmp/#{@report_name}/#{params[:node]}/pengine/#{params[:basename]}.bz2",
        params[:format] == "xml" ? "-G" : "-D", tmpfile.path)
      # TODO(must): handle failure of above

      if params[:format] == "xml"
        # Can't use send_file here, server whines about file not existing(?!?)
        send_data File.new(tmpfile.path).read, :type => "text/xml", :disposition => "inline"
      else
        stdin, stdout, stderr, thread = Util.popen3("/usr/bin/dot", "-Tpng", tmpfile.path)
        stdin.close
        png = stdout.read
        stdout.close
        stderr.close
        # TODO(must): check thread.value.exitstatus
        send_data png, :type => "image/png", :disposition => "inline"
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
    if File.exists?(@pidfile) && File.exists?(@timefile)
      # If we're already running, use the last run time & date
      @from_time, @to_time = File.new(@timefile).read.split(",")
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
    @report_path = "/tmp/#{@report_name}.tar.bz2"
  end

  # Note: This assumes pidfile doesn't exist (will always blow away what's there),
  # so there's a possibility of a race (or lost hb_report status) if two users kick
  # off generation at almost exactly the same time.
  # THIS IS (ALMOST) A FLAT OUT COPY OF HbReportsController::generate...
  def generate
    [@outfile, @errfile, @exitfile].each do |fn|
      File.unlink(fn) if File.exists?(fn)
    end

    pid = fork {
      f = File.new(@pidfile, "w")
      f.write(Process.pid)
      f.close

      f = File.new(@timefile, "w")
      f.write("#{@from_time},#{@to_time}")
      f.close

      args = ["-f", @from_time]
      args.push "-t", @to_time
      # TODO(must): consolidate with paths above
      args.push "/tmp/#{@report_name}"
      stdin, stdout, stderr, thread = Util.run_as("root", "hb_report", *args)
      stdin.close
      f = File.new(@outfile, "w")
      f.write(stdout.read())
      f.close
      stdout.close
      f = File.new(@errfile, "w")
      f.write(stderr.read())
      f.close
      stderr.close

      # Record exit status
      f = File.new(@exitfile, "w")
      f.write(thread.value.exitstatus)
      f.close
      # TODO(must): somehow record a failed run -- "/tmp/#{@report_name}.err" ?

      # Delete pidfile
      File.unlink(@pidfile)
    }
    Process.detach(pid)
  end

end
