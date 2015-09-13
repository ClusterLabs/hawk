# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

# Need to be able to:
# - Check if any crm history command is active (only want one run at a time)
# - Know which crm history command is active
# - Get last run time and last run command
# - Get last run exitstatus, stdout, stderr
# - Run new command

module CrmHistory
  @pidfile = "#{Rails.root}/tmp/pids/crm_history.pid"
  @cmdfile = "#{Rails.root}/tmp/pids/crm_history.cmd"
  @outfile = "#{Rails.root}/tmp/pids/crm_history.stdout"
  @errfile = "#{Rails.root}/tmp/pids/crm_history.stderr"
  @exitfile = "#{Rails.root}/tmp/pids/crm_history.exit"

  def active?
    Util.child_active(@pidfile)
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

    f = File.new(@cmdfile, "w")
    f.write(cmd.join(" "))
    f.close
    pid = fork {
      out, err, status = Util.run_as("root", "crm", "history", *cmd)
      f = File.new(@outfile, "w")
      f.write(out)
      f.close
      f = File.new(@errfile, "w")
      f.write(err)
      f.close

      f = File.new(@exitfile, "w")
      f.write(status.exitstatus)
      f.close
      File.unlink(@pidfile)
    }
    f = File.new(@pidfile, "w")
    f.write(pid)
    f.close
    Process.detach(pid)

    # Note: don't rely on there being any progressive status text
  end
  module_function :run
end
