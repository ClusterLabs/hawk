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

class User < Record
  attribute :id, String
  attribute :roles, Array[String]

  validates :id,
    presence: { message: _('User ID is required') },
    format: { with: /^[a-zA-Z0-9_-]+$/, message: _('Invalid User ID') }

  def roles
    @roles ||= Array.new
  end

  protected

  def shell_syntax
    [].tap do |cmd|
      cmd.push "acl_target #{id}"

      roles.each do |role|
        cmd.push role
      end
    end.join(' ')
  end

  class << self
    def instantiate(xml)
      record = allocate

      xml.elements.each do |elem|
        if elem.name == 'role'
          record.roles.push elem.attributes['id']
        end
      end

      record
    end

    def cib_type
      :acl_target
    end
  end
end
