#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
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

class Session < Tableless
  HAWK_CHKPWD = "/usr/sbin/hawk_chkpwd"

  attribute :username, String
  attribute :password, String

  validates :username, format: { with: /[^'$]+/, message: _("Invalid username") }

  validate do |record|
    first_checks_valid = true

    unless File.exists? HAWK_CHKPWD
      record.errors[:base] << _("%s is not installed") % HAWK_CHKPWD
      first_checks_valid = false
    end

    unless File.executable? HAWK_CHKPWD
      record.errors[:base] << _("%s is not executable") % HAWK_CHKPWD
      first_checks_valid = false
    end

    if record.username.nil?
      record.errors[:base] << _("Username not specified")
      first_checks_valid = false
    end

    if record.password.nil?
      record.errors[:base] << _("Password not specified")
      first_checks_valid = false
    end

    if first_checks_valid
      IO.popen(auth_command_for(record.username), "w+") do |pipe|
        pipe.write record.password
        pipe.close_write
      end

      unless $?.exitstatus == 0
        record.errors[:base] << _("Invalid username or password")
      end
    end
  end

  protected

  def auth_command_for(username)
    [
      HAWK_CHKPWD,
      "passwd",
      username.shellescape
    ].join(" ")
  end
end
