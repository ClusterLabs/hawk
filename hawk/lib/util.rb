#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
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

# Random utilities
module Util

  # From Ruby's lib/open3.rb, but actually sets $?
  # TODO(should): submit this as a patch to Ruby.  Refer to
  # rejected bug http://redmine.ruby-lang.org/issues/show/1287
  def popen3(*cmd)
    pw = IO::pipe   # pipe[0] for read, pipe[1] for write
    pr = IO::pipe
    pe = IO::pipe

    pid = fork{
      # child
      fork{
        # grandchild
        pw[1].close
        STDIN.reopen(pw[0])
        pw[0].close

        pr[0].close
        STDOUT.reopen(pr[1])
        pr[1].close

        pe[0].close
        STDERR.reopen(pe[1])
        pe[1].close

        exec(*cmd)
      }
      # Originally the below was just "exit!(0)"
      Process.wait
      exit!($?.exitstatus)
    }

    pw[0].close
    pr[1].close
    pe[1].close
    Process.waitpid(pid)
    pi = [pw[1], pr[0], pe[0]]
    pw[1].sync = true
    if defined? yield
      begin
        return yield(*pi)
      ensure
        pi.each{|p| p.close unless p.closed?}
      end
    end
    pi
  end
  module_function :popen3

  # Same as popen3, but sets CRM_USER beforehand
  def run_as(user, *cmd)
    ENV['CRM_USER'] = user
    pi = popen3(*cmd)
    ENV.delete('CRM_USER')
    if defined? yield
      begin
        return yield(*pi)
      ensure
        pi.each{|p| p.close unless p.closed?}
      end
    end
    pi
  end
  module_function :run_as

end
