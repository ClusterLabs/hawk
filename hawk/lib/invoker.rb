# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'singleton'

class NotFoundError < RuntimeError
end

#
# Singleton class for invoking crm configuration tools as the current
# user, obtained by trickery from ApplicationController, which injects
# a "current_user" method into this class.
#
class Invoker
  include Singleton
  include FastGettext::Translation
  include Util

  # Invoke some command, returning true or [exitstatus, message]
  # as appropriate (refactored somewhat from MainController::invoke,
  # and suspiciously similar to invoke_crm - obviously this can be
  # cleaned up further)
  def run(*cmd)
    out, err, status = Util.run_as(current_user, *cmd)
    fudge_error(status.exitstatus, err)
  end

  # Run "crm [...]"
  # Returns 'true' on successful execution, or STDERR output on failure.
  def crm(*cmd)
    invoke_crm(nil, *cmd)
  end

  # Run "crm configure", passing input via STDIN.
  # Returns 'true' on successful execution, or STDERR output on failure.
  def crm_configure(input)
    invoke_crm(input, "configure")
  end

  # Run "crm script" as root to execute cluster scripts.
  # Returns 'true' on successful execution, or STDERR output on failure.
  def crm_script(rootpw, scriptdir, *cmd)
    cmd2 = ["crm", "--scriptdir=#{scriptdir}", "script"] + cmd
    CrmEvents.instance.push cmd2
    # TODO(must): figure out if this join thing is kosher (should be, all input looks like plain text... :-/)
    out, err, status = Util.capture3('/usr/bin/su', '--login', 'root', '-c', cmd2.join(' '), :stdin_data => rootpw)
    result = ""
    err.split("\n").each do |line|
      result += line unless line.starts_with?('Password:')
    end
    result = fudge_error(status.exitstatus, result)
    result == true ? true : result[1]
  end

  # Run "crm -F configure load update"
  # Returns 'true' on successful execution, or STDERR output on failure.
  def crm_configure_load_update(cmd)
    require 'tempfile.rb'
    f = Tempfile.new 'crm_config_update'
    f << cmd
    f.close
    # Evil to allow unprivileged user running crm shell to read the file
    # TODO(should): can we just allow group (probably ok live, but no
    # good for testing when running as root), or some other alternative
    # with piping data to crm?
    File.chmod(0666, f.path)
    CrmEvents.instance.push "#{f.path} = #{cmd}"
    result = crm('-F', 'configure', 'load', 'update', f.path)
    f.unlink
    result
  end

  # Invoke cibadmin with command line arguments.  Returns stdout as string,
  # Raises NotFoundError, SecurityError or RuntimeError on failure.
  def cibadmin(*cmd)
    out, err, status = run_as(current_user, 'cibadmin', *cmd)
    case status.exitstatus
    when 0
      return out
    when 6, 22 # cib_NOTEXISTS (used to be 22, now it's 6...)
      raise NotFoundError, _('The object/attribute does not exist (cibadmin %{cmd})') % {:cmd => cmd.inspect}
    when 13, 54 # cib_permission_denied (used to be 54, now it's 13...)
      raise SecurityError, _('Permission denied for user %{user}') % {:user => current_user}
    else
      raise RuntimeError, _('Error invoking cibadmin %{cmd}: %{msg}') % {:cmd => cmd.inspect, :msg => err}
    end
    # Never reached
  end

  # Invoke "cibadmin -p --replace"
  # TODO(should): Can this be conveniently consolidated with the above?
  def cibadmin_replace(xml)
    out, err, status = run_as(current_user, 'cibadmin', '-p', '--replace', :stdin_data => xml)
    case status.exitstatus
    when 0
      return true
    when 6, 22 # cib_NOTEXISTS (used to be 22, now it's 6...)
      raise NotFoundError, _('The object/attribute does not exist: %{msg}') % {:msg => err}
    when 13, 54 # cib_permission_denied (used to be 54, now it's 13...)
      raise SecurityError, _('Permission denied for user %{user}') % {:user => current_user}
    else
      raise RuntimeError, _('Error invoking cibadmin --replace: %{msg}') % {:msg => err}
    end
    # Never reached
  end

  # Used by the simulator
  def crm_simulate(*cmd)
    run_as(current_user, 'crm_simulate', *cmd)
  end

  private

  # Returns 'true' on successful execution, or STDERR output on failure.
  def invoke_crm(input, *cmd)
    if input
      CrmEvents.instance.push "crm #{cmd.join(' ')}\n#{input}"
    else
      CrmEvents.instance.push "crm #{cmd.join(' ')}"
    end
    cmd << { :stdin_data => input }
    out, err, status = run_as(current_user, 'crm', *cmd)
    result = fudge_error(status.exitstatus, err)
    result == true ? true : result[1]
  end

  # Note that this is horribly rough - "crm configure delete"
  # returns 0 (success) if a resource can't be deleted because it's
  # running, so we assume failure if the command output includes
  # "WARNING" or "ERROR".  *sigh*
  # Actually, the above should be fixed as of 2011-03-17 (bnc#680401)
  # ...but as of 2011-08-31, it's not fixed at least in the case of
  # "Call cib_replace failed (-54): Permission Denied"...
  # TODO(must): Evaluate cases where we have WARNING but no ERROR.  These
  # may be false positives (e.g. when creating STONITH resources: "Unable
  # to create resource: 'WARNING: 1: ra class stonith does not support
  # providers'"
  def fudge_error(exitstatus, stderr)
    if exitstatus == 0 && !(stderr.upcase.index("ERROR") || stderr.upcase.index("WARNING"))
      true
    elsif exitstatus == 0 && stderr.index("WARNING: Creating rsc_location constraint") && !stderr.index("ERROR")
      # Special case for "crm resource migrate" with no node specified, to squash
      # warning about persistent location constraint (remember my *sigh* in the
      # comment above?)
      true
    else
      if stderr.match(/-54.*permission denied/i) || stderr.match(/-13.*permission denied/i)
        stderr = _('Permission denied for user %{user}') % {:user => current_user}
      end
      [exitstatus, stderr]
    end
  end

  def current_user
    Thread.current[:current_user].call
  end
end

