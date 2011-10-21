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

class HbReport
  attr_reader :outfile, :errfile, :lastexit

  # Call with e.g.: "#{RAILS_ROOT}/tmp/pids/hb_report".  pidfile etc.
  # will be set based on this path.
  def initialize(tmpbase)
    @pidfile  = "#{tmpbase}.pid"
    @outfile  = "#{tmpbase}.stdout"
    @errfile  = "#{tmpbase}.stderr"
    @exitfile = "#{tmpbase}.exit"
    @timefile = "#{tmpbase}.time"
    @lastexit = File.exists?(@exitfile) ? File.new(@exitfile).read.to_i : nil
  end

  def running?
    File.exists?(@pidfile)
  end

  # Returns [from_time, to_time], as strings.  Note that to_time might be
  # an empty string, if no to_time was specified when calling generate.
  def lasttime
    File.exists?(@timefile) ? File.new(@timefile).read.split(",", -1) : nil
  end

  # Note: This assumes pidfile doesn't exist (will always blow away what's
  # there), so there's a possibility of a race (or lost hb_report status)
  # if two clients kick off generation at almost exactly the same time.
  # from_time and to_time (if specified) are expected to be in a sensible
  # format (e.g.: "%Y-%m-%d %H:%M")
  def generate(path, from_time, all_nodes=true, to_time=nil)
    [@outfile, @errfile, @exitfile, @timefile].each do |fn|
      File.unlink(fn) if File.exists?(fn)
    end
    @lastexit = nil

    pid = fork {
      f = File.new(@pidfile, "w")
      f.write(Process.pid)
      f.close

      f = File.new(@timefile, "w")
      f.write("#{from_time},#{to_time}")
      f.close

      args = ["-f", from_time]
      args.push("-t", to_time) if to_time
      args.push("-Z")  # Remove destination directories if they exist
      args.push("-S") unless all_nodes
      args.push(path)

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
  end
end
