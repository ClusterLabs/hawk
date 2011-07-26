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
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#======================================================================

# Need to be able to:
# - Check if any crm history command is active (only want one run at a time)
# - Know which crm history command is active
# - Get last run time and last run command
# - Get last run exitstatus, stdout, stderr
# - Run new command

module CrmHistory
  @pidfile = "#{RAILS_ROOT}/tmp/pids/crm_history.pid"
  @cmdfile = "#{RAILS_ROOT}/tmp/pids/crm_history.cmd"
  @outfile = "#{RAILS_ROOT}/tmp/pids/crm_history.stdout"
  @errfile = "#{RAILS_ROOT}/tmp/pids/crm_history.stderr"
  @exitfile = "#{RAILS_ROOT}/tmp/pids/crm_history.exit"

  def active?
    File.exists?(@pidfile)
  end
  module_function :active?

  # Command returned is e.g.: "node node-1", not "crm history node node-1"
  def active_cmd
    return [] unless File.exists?(@cmdfile)
    File.new(@cmdfile).read.split(/\s/)
  end
  module_function :active_cmd

  # Last run time is the mtime of the exit file (last thing written)
  def last_run_cmd
    return [] unless File.exists?(@cmdfile) && File.exists?(@exitfile)
    [File.new(@exitfile).mtime] + File.new(@cmdfile).read.split(/\s/)
  end
  module_function :last_run_cmd

  def last_run_result
    return [] unless File.exists?(@exitfile) && File.exists?(@outfile) && File.exists?(@errfile)
    [File.new(@exitfile).read.to_i, File.new(@outfile).read, File.new(@errfile).read]
  end
  module_function :last_run_result

  # Call this as CrmHistory.run("node", "node-1") or similar, i.e.
  # this command will be run in the context of "crm history" automatically.
  #
  # Note: As with HbReportsController::generate, this assumes pidfile
  # doesn't exist (will always blow away what's there), so there's a
  # possibility of a race (or lost crm history status) if two users
  # kick off a run at almost exactly the same time.
  def run(*cmd)
    [@cmdfile, @outfile, @errfile, @exitfile].each do |fn|
      File.unlink(fn) if File.exists?(fn)
    end

    pid = fork {
      f = File.new(@pidfile, "w")
      f.write(Process.pid)
      f.close

      f = File.new(@cmdfile, "w")
      f.write(cmd.join(" "))
      f.close

      stdin, stdout, stderr, thread = Util.run_as("root", "crm", "history", *cmd)
      stdin.close
      f = File.new(@outfile, "w")
      f.write(stdout.read())
      f.close
      stdout.close
      f = File.new(@errfile, "w")
      f.write(stderr.read())
      f.close
      stderr.close

      f = File.new(@exitfile, "w")
      f.write(thread.value.exitstatus)
      f.close
      File.unlink(@pidfile)
    }
    Process.detach(pid)

    # Note: don't rely on there being any progressive status text
  end
  module_function :run
end
