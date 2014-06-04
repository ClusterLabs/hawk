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
    @rules = []
    @roles = []
    super
  end

  def validate
    @roles = @roles.delete_if{|r| r.empty?}
    @rules = @rules.delete_if{|r| r[:right].empty? && r[:xpath].empty? && r[:tag].empty? && r[:ref].empty? && r[:attribute].empty?}
    # TODO(must): get rid of embedded space, non valid chars etc.
    @rules.each do |r|
      r[:tag].strip!
      r[:ref].strip!
      r[:xpath].strip!
      r[:attribute].strip!
    end
    # TODO(must): get rid of completely empty rules!
    error _('User must have either rules or roles') if @rules.empty? && @roles.empty?
    error _("User can't have both rules and roles") if !@rules.empty? && !@roles.empty?
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
    unless CibObject.exists?(id, 'acl_user')
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
      rules = []
      roles = []
      xml.elements.each do |elem|
        if elem.name == 'role_ref'
          roles << elem.attributes['id']
        else
          rules << {
            :right      => elem.name,
            :tag        => elem.attributes['tag'] || nil,
            :ref        => elem.attributes['ref'] || nil,
            :xpath      => elem.attributes['xpath'] || nil,
            :attribute  => elem.attributes['attribute'] || nil
          }
        end
      end
      acl.instance_variable_set(:@rules, rules);
      acl.instance_variable_set(:@roles, roles);
      acl
    end

    def all
      super "acl_user"
    end
  end

  private

  def shell_syntax
    cmd = "user #{@id}"
    @roles.each do |role|
      cmd += " role:#{role}"
    end
    @rules.each do |rule|
      cmd += " #{rule[:right]} "
      cmd += " tag:#{rule[:tag]}" if rule[:tag] && !rule[:tag].empty?
      cmd += " ref:#{rule[:ref]}" if rule[:ref] && !rule[:ref].empty?
      cmd += " xpath:#{rule[:xpath]}" if rule[:xpath] && !rule[:xpath].empty?
      cmd += " attribute:#{rule[:tag]}" if rule[:attribute] && !rule[:attribute].empty?
    end
    cmd
  end

end

