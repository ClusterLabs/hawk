#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2012 Novell Inc., All Rights Reserved.
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

# Random utilities
module Util

  # Derived from Ruby 1.8's and 1.9's lib/open3.rb.  Returns
  # [stdin, stdout, stderr, thread].  thread.value.exitstatus
  # has the exit value of the child, but if you're calling it
  # in non-block form, you need to close stdin, out and err
  # else the process won't be complete when you try to get the
  # exit status.
  def popen3(*cmd)
    raise SecurityError, "Util::popen3 called with < 2 args" if cmd.length < 2
    pw = IO::pipe   # pipe[0] for read, pipe[1] for write
    pr = IO::pipe
    pe = IO::pipe

    pid = fork{
      # child
      pw[1].close
      STDIN.reopen(pw[0])
      pw[0].close

      pr[0].close
      STDOUT.reopen(pr[1])
      pr[1].close

      pe[0].close
      STDERR.reopen(pe[1])
      pe[1].close

      # RORSCAN_INL: cmd always has > 1 elem, so safe from shell injection
      exec(*cmd)
    }
    wait_thr = Process.detach(pid)

    pw[0].close
    pr[1].close
    pe[1].close
    pi = [pw[1], pr[0], pe[0], wait_thr]
    pw[1].sync = true
    if defined? yield
      begin
        return yield(*pi)
      ensure
        pi.each{|p| p.close if p.respond_to?(:closed) && !p.closed?}
        wait_thr.join
      end
    end
    pi
  end
  module_function :popen3

  # Like popen3, but via /usr/sbin/hawk_invoke
  def run_as(user, *cmd)
    old_home = ENV['HOME']
    ENV['HOME'] = begin
      require 'etc'
      Etc.getpwnam(user)['dir']
    rescue ArgumentError
      # user doesn't exist - this can't happen[tm], but just in case
      # return an empty string so the existence test below fails
      ''
    end
    unless File.exists?(ENV['HOME'])
      # crm shell always wants to open/generate help index, so if the
      # user has no actual home directory, set it to a subdirectory
      # inside tmp/home, but make sure it's 0770, because it'll be
      # created with uid hacluster, but the user we become (in the
      # haclient group) also needs to be able to write as *that* user.
      ENV['HOME'] = File.join(RAILS_ROOT, 'tmp', 'home', user)
      unless File.exists?(ENV['HOME'])
        umask = File.umask(0002)
        Dir.mkdir(ENV['HOME'], 0770)
        File.umask(umask)
      end
    end
    # RORSCAN_INL: mutli-arg invocation safe from shell injection.
    pi = popen3('/usr/sbin/hawk_invoke', user, *cmd)
    # Having invoked a command, reset $HOME to what it was before,
    # else it sticks, and other (non-invoker) crm invoctiaons, e.g.
    # has_feature() run the shell as hacluster, which in turn causes
    # $HOME/.cache and $HOME/.config to revert to 600 with uid hacluster,
    # which means the *next* call after that will die with permission
    # problems, and you will spend an entire day debugging it.
    ENV['HOME'] = old_home
    if defined? yield
      begin
        return yield(*pi)
      ensure
        pi.each{|p| p.close if p.respond_to?(:closed) && !p.closed?}
      end
    end
    pi
  end
  module_function :run_as

  # Like %x[...], but without risk of shell injection.  Returns STDOUT
  # as a string.  STDERR is ignored. $?.exitstatus is set appropriately.
  # May block indefinitely if the command executed is expecting something
  # on STDIN (untested)
  def safe_x(*cmd)
    raise SecurityError, "Util::safe_x called with < 2 args" if cmd.length < 2
    pr = IO::pipe   # pipe[0] for read, pipe[1] for write
    pe = IO::pipe
    pid = fork{
      # child
      fork{
        # grandchild
        pr[0].close
        STDOUT.reopen(pr[1])
        pr[1].close
        pe[0].close
        STDERR.reopen(pe[1])
        pe[1].close
        # RORSCAN_INL: cmd always has > 1 elem, so safe from shell injection
        exec(*cmd)
      }
      Process.wait
      exit!($?.exitstatus)
    }
    Process.waitpid(pid)
    pr[1].close
    pe[1].close
    out = pr[0].read()
    pr[0].close
    out
  end
  module_function :safe_x

  # Check if a child process is active by pidfile, but also cleanup stale
  # pidfile if child has gone away unexpectedly.
  def child_active(pidfile)
    active = false
    if File.exists?(pidfile)
      pid = File.new(pidfile).read.to_i
      if pid > 0
        begin
          active = Process.getpgid(pid) == Process.getpgid(0)
        rescue Errno::ESRCH
          # no such process (but nothing to do; active is already false)
        end
      end
      File.unlink(pidfile) unless active
    end
    active
  end
  module_function :child_active

  # Gives back a string, boolean if value is "true" or "false", or nil
  # if initial value was nil (or boolean false) and there's no default
  # TODO(should): be nice to get integers auto-converted too
  def unstring(v, default = nil)
    v ||= default
    ['true', 'false'].include?(v.class == String ? v.downcase : v) ? v.downcase == 'true' : v
  end
  module_function :unstring

  # Does the same job bas crm_get_msec() from lib/common/utils.c
  def crm_get_msec(str)
    m = str.strip.match(/^([0-9]+)(.*)$/)
    return -1 unless m
    msec = m[1].to_i
    case m[2]
    when "ms", "msec"
      msec
    when "us", "usec"
      msec / 1000
    when "s", "sec", ""
      msec * 1000
    when "m", "min"
      msec * 60 * 1000
    when "h", "hr"
      msec * 60 * 60 * 1000
    else
      -1
    end
  end
  module_function :crm_get_msec

  # Check if some feature is supported by the installed version of pacemaker.
  # TODO(should): expand to include other checks (e.g. pcmk installed).
  def has_feature?(feature)
    case feature
    when :crm_history
      PerRequestCache.fetch(:has_crm_history) {
        %x[echo quit | /usr/sbin/crm history 2>&1]
        $?.exitstatus == 0
      }
    when :rsc_ticket
      PerRequestCache.fetch(:has_rsc_ticket) {
        %x[/usr/sbin/crm configure rsc_ticket 2>&1].starts_with?("usage")
      }
    when :rsc_template
      PerRequestCache.fetch(:has_rsc_template) {
        %x[/usr/sbin/crm configure rsc_template 2>&1].starts_with?("usage")
      }
    when :sim_ticket
      PerRequestCache.fetch(:has_sim_ticket) {
        %x[/usr/sbin/crm_simulate -h 2>&1].include?("--ticket-grant")
      }
    else
      false
    end
  end
  module_function :has_feature?

  # get text child of xml element - returns empty string if elem is nil or
  # text child is empty.  trims leading and trailing whitespace
  def get_xml_text(elem)
    elem ? (elem.text.strip || '') : ''
  end
  module_function :get_xml_text
end
