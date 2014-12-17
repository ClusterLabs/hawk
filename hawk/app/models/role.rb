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

class Role < CibObject
  @attributes = :rules
  attr_accessor *@attributes

  def initialize(attributes = nil)
    @rules = []
    super
  end

  def validate
    # TODO(must): get rid of embedded space, non valid chars etc.
    @rules.each do |r|
      r[:tag].strip!
      r[:ref].strip!
      r[:xpath].strip!
      r[:attribute].strip!
    end
    # TODO(must): get rid of completely empty rules!
  end

  def create
    if CibObject.exists?(id)
      error _('The ID "%{id}" is already in use') % { :id => @id }
      return false
    end
    cmd = shell_syntax
    result = Invoker.instance.crm_configure cmd
    unless result == true
      error _('Unable to create role: %{msg}') % { :msg => result }
      return false
    end
    true
  end

  def update
    unless CibObject.exists?(id, 'acl_role')
      error _('Role ID "%{id}" does not exist') % { :id => @id }
      return false
    end
    result = Invoker.instance.crm_configure_load_update shell_syntax
    unless result == true
      error _('Unable to update role: %{msg}') % { :msg => result }
      return false
    end
    true
  end

  def update_attributes(attributes = nil)
    @rules = []
    super
  end

  class << self
    def instantiate(xml)
      acl = allocate
      rules = []
      xml.elements.each do |elem|
        rules << {
          :right      => elem.attributes['kind'],
          :tag        => elem.attributes['object-type'] || nil,
          :ref        => elem.attributes['reference'] || nil,
          :xpath      => elem.attributes['xpath'] || nil,
          :attribute  => elem.attributes['attribute'] || nil
        }
      end
      acl.instance_variable_set(:@rules, rules);
      acl
    end

    def all
      super "acl_role"
    end

    def ordered
      all.sort do |a, b|
        a.id.natcmp(b.id, true)
      end
    end
  end

  private

  def shell_syntax
    cmd = "role #{@id}"
    @rules.each do |rule|
      cmd += " #{rule[:right]} "
      cmd += " tag:#{rule[:tag]}" if rule[:tag] && !rule[:tag].empty?
      cmd += " ref:#{rule[:ref]}" if rule[:ref] && !rule[:ref].empty?
      cmd += " xpath:#{rule[:xpath]}" if rule[:xpath] && !rule[:xpath].empty?
      cmd += " attribute:#{rule[:attribute]}" if rule[:attribute] && !rule[:attribute].empty?
    end
    Rails.logger.debug(cmd)
    cmd
  end

end

