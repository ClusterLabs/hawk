#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., All Rights Reserved.
#
# Author: Tim Serong <tserong@novell.com>
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

class HbReportsController < ApplicationController
  before_filter :login_required, :ensure_godlike

  # Not specifying layout because all we do ATM is show individual node details
  # layout 'main'

  def initialize
    @pidfile = "#{RAILS_ROOT}/tmp/pids/hb_report.pid"
    @outfile = "#{RAILS_ROOT}/tmp/pids/hb_report.stdout"
    @errfile = "#{RAILS_ROOT}/tmp/pids/hb_report.stderr"
    @exitfile = "#{RAILS_ROOT}/tmp/pids/hb_report.exit"

    @lastexit = File.exists?(@exitfile) ? File.new(@exitfile).read.to_i : nil
  end

  # List all extant hb_reports
  # TODO(should): track old hb reports
  def index
  end

  # Show form for generating hb_report, or indicator if one is already generating
  def new
  end

  # Kick off hb_report generation
  def create
    if !File.exists?(@pidfile)
      from_time = params[:from_time] || ""
      from_time.strip!
      to_time = params[:to_time] || ""
      to_time.strip!
      if from_time.empty?
        # TODO(should): Better error messages (just have an alert box ATM)
        @error = true
      else
        generate(from_time, true, to_time.empty? ? nil : to_time)
      end
    end
  end

  # TODO(should): Show stderr & stdout from last run when complete
  def status
    render :create
  end

  # Download hb_report
  # TODO(should): Allow downloading arbitrary hb_report
  def show
    if File.exists?("/tmp/hb_report-hawk.tar.bz2")
      send_file "/tmp/hb_report-hawk.tar.bz2"
    else
      render :status => :not_found
    end
  end

  private

  # Note: This assumes pidfile doesn't exist (will always blow away what's there),
  # so there's a possibility of a race (or lost hb_report status) if two users kick
  # off generation at almost exactly the same time.
  def generate(from_time, all_nodes=true, to_time=nil)
    [@outfile, @errfile, @exitfile].each do |fn|
      File.unlink(fn) if File.exists?(fn)
    end
    @lastexit = nil

    pid = fork {
      f = File.new(@pidfile, "w")
      f.write(Process.pid)
      f.close

      args = ["-f", from_time]
      args.push "-t", to_time if to_time
      args.push "-Z"  # Remove destination directories if they exist
      args.push "-S" unless all_nodes
      args.push "/tmp/hb_report-hawk"
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
      # Delete pidfile
      File.unlink(@pidfile)
    }
    Process.detach(pid)

    # Note: this won't give any progressive status text, i.e. stdout
    # and stderr aren't available until the run is complete.
    true
  end

  # TODO(should): Look at shifting this logic completely to ApplicationController (see login_required)
  def ensure_godlike
    unless is_god?
      render :permission_denied
    end
  end
end
