#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011-2014 SUSE LLC, All Rights Reserved.
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

class User < CibObject
  @attributes = :rules, :roles
  attr_accessor *@attributes

  def initialize(attributes = nil)
    @roles = []
    super
  end

  def validate
    @roles = @roles.delete_if{|r| r.empty?}
    # TODO(must): get rid of embedded space, non valid chars etc.
  end

  def create
    if CibObject.exists?(id)
      error _('The ID "%{id}" is already in use') % { :id => @id }
      return false
    end
    cmd = shell_syntax
    result = Invoker.instance.crm_configure cmd
    unless result == true
      error _('Unable to create user: %{msg}') % { :msg => result }
      return false
    end
    true
  end

  def update
    unless CibObject.exists?(id, 'acl_target')
      error _('User ID "%{id}" does not exist') % { :id => @id }
      return false
    end
    result = Invoker.instance.crm_configure_load_update shell_syntax
    unless result == true
      error _('Unable to update user: %{msg}') % { :msg => result }
      return false
    end
    true
  end

  def update_attributes(attributes = nil)
    @rules = []
    @roles = []
    super
  end

  class << self
    def instantiate(xml)
      acl = allocate
      # Just to be confusing... ;)
      roles = []
      xml.elements.each do |elem|
        if elem.name == 'role'
          roles << elem.attributes['id']
        end
      end
      acl.instance_variable_set(:@roles, roles);
      acl
    end

    def all
      super "acl_target"
    end

    def ordered
      all.sort do |a, b|
        a.id.natcmp(b.id, true)
      end
    end
  end

  private

  def shell_syntax
    cmd = "acl_target #{@id}"
    @roles.each do |role|
      cmd += " #{role}"
    end
    cmd
  end

end

