#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
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

class NotFoundError < RuntimeError
end

#
# Singleton class for invoking crm configuration tools as the current
# user, obtained by trickery from ApplicationController, which injects
# a "current_user" method into this class.
#
class Invoker
  include GetText

  @@instance = Invoker.new
  def self.instance
    return @@instance
  end
  private_class_method :new

  include Util

  # Run "crm [...]"
  # Returns 'true' on successful execution, or STDOUT+STDERR output on
  # failure.  Note that this is horribly rough - "crm configure delete"
  # returns 0 (success) if a resource can't be deleted because it's
  # running, so we assume failure if the command output includes
  # "WARNING" or "ERROR".  *sigh*
  # TODO(should): Can this be conveniently consolidated with the below?
  def crm(*cmd)
    stdin, stdout, stderr, thread = run_as(current_user, 'crm', *cmd)
    stdin.close
    result = stdout.read()
    stdout.close
    result += stderr.read()
    stderr.close
    thread.value.exitstatus == 0 && !(result.index("ERROR") || result.index("WARNING")) ? true : result
  end

  # Run "crm configure", passing input via STDIN.
  # Returns 'true' on successful execution, or STDERR output on failure.
  def crm_configure(cmd)
    stdin, stdout, stderr, thread = run_as(current_user, 'crm', 'configure')
    stdin.write(cmd)
    stdin.close
    stdout.close
    result = stderr.read()
    stderr.close
    thread.value.exitstatus == 0 ? true : result
  end

  # Invoke cibadmin with command line arguments.  Returns stdout as string,
  # Raises NotFoundError, SecurityError or RuntimeError on failure.
  def cibadmin(*cmd)
    stdin, stdout, stderr, thread = run_as(current_user, 'cibadmin', *cmd)
    stdin.close
    out = stdout.read()
    stdout.close
    err = stderr.read()
    stderr.close
    case thread.value.exitstatus
    when 0
      return out
    when 22 # cib_NOTEXISTS
      raise NotFoundError, _('The object/attribute does not exist (cibadmin %{cmd})') % {:cmd => cmd.inspect}
    when 54 # cib_permission_denied
      raise SecurityError, _('Permission denied for user %{user}') % {:user => current_user}
    else
      raise RuntimeError, _('Error invoking cibadmin %{cmd}: %{msg}') % {:cmd => cmd.inspect, :msg => err}
    end
    # Never reached
  end

  # Invoke "cibadmin -p --replace"
  # TODO(should): Can this be conveniently consolidated with the above?
  def cibadmin_replace(xml)
    stdin, stdout, stderr, thread = run_as(current_user, 'cibadmin', '-p', '--replace')
    stdin.write(xml)
    stdin.close
    stdout.close
    err = stderr.read()
    stderr.close
    case thread.value.exitstatus
    when 0
      return true
    when 22 # cib_NOTEXISTS
      raise NotFoundError, _('The object/attribute does not exist (cibadmin %{cmd})') % {:cmd => cmd.inspect}
    when 54 # cib_permission_denied
      raise SecurityError, _('Permission denied for user %{user}') % {:user => current_user}
    else
      raise RuntimeError, _('Error invoking cibadmin %{cmd}: %{msg}') % {:cmd => cmd.inspect, :msg => err}
    end
    # Never reached
  end
end

