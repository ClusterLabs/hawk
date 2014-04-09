#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2012-2013 SUSE LLC, All Rights Reserved.
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
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#======================================================================

# This thing is what the crm shell refers to as rsc_ticket (and indeed,
# that's what it is in the CIB too), but we're calling it Ticket for
# consistency with Hawk's Location, Order and Colocation nomenclature.
# I figured the least worst choice was to maintain consistent naming
# within Hawk source, although...  For "perfection" (hah!) we'd be
# better off more rigidly following the CIB and use RscTicket, RscOrder,
# RscColocation, RscLocation.
# TODO(could): Revisit naming of constraint classes

# Note: Unlike Colocation and Order (which always fold to resource set
# notation), @resources is just a flat array with each element specifying
# resource ID and role.  Trust me, it's easier that way.

class Ticket < Constraint
  @attributes = :ticket, :resources, :loss_policy
  attr_accessor *@attributes

  def initialize(attributes = nil)
    @ticket       = nil
    @resources    = []
    @loss_policy  = nil
    super
  end

  def validate
    @ticket.strip!
    if @ticket.empty? || !@ticket.match(/^[a-zA-Z0-9_-]+$/)
      error _('Invalid Ticket ID')
    end
    if @resources.empty?
      error _('No resources specified')
    end
    @loss_policy.strip!
    @loss_policy = nil if @loss_policy.empty?
    @resources.each do |r|
      r[:role].strip!
      r[:role] = nil if r[:role].empty?
    end
  end

  def create
    if CibObject.exists?(id)
      error _('The ID "%{id}" is already in use') % { :id => @id }
      return false
    end

    cmd = shell_syntax

    result = Invoker.instance.crm_configure cmd
    unless result == true
      error _('Unable to create constraint: %{msg}') % { :msg => result }
      return false
    end

    true
  end

  def update
    unless CibObject.exists?(id, 'rsc_ticket')
      error _('Constraint ID "%{id}" does not exist') % { :id => @id }
      return false
    end

    # Can just use crm configure load update here, it's trivial enough (because
    # we basically replace the object every time, rather than having to merge
    # like primitive, ms, etc.)

    result = Invoker.instance.crm_configure_load_update shell_syntax
    unless result == true
      error _('Unable to update constraint: %{msg}') % { :msg => result }
      return false
    end

    true
  end

  def update_attributes(attributes = nil)
    @ticket       = nil
    @resources    = []
    @loss_policy  = nil
    super
  end

  class << self
    def instantiate(xml)
      con = allocate
      con.instance_variable_set(:@ticket, xml.attributes['ticket'] || nil)
      resources = []
      if xml.attributes['rsc']
        # Simple (one resource) constraint
        resources << {
          :id   => xml.attributes['rsc'],
          :role => xml.attributes['rsc-role'] || nil
        }
      else
        # Resource set
        xml.elements.each do |resource_set|
          role = resource_set.attributes['role'] || nil
          resource_set.elements.each do |e|
            resources << {
              :id   => e.attributes['id'],
              :role => role
            }
          end
        end
      end
      con.instance_variable_set(:@resources, resources)
      con.instance_variable_set(:@loss_policy, xml.attributes['loss-policy'] || nil)
      con
    end
  end

  private

  def shell_syntax
    cmd = "rsc_ticket #{@id} #{@ticket}:"
    @resources.each do |r|
      cmd += " #{r[:id]}"
      cmd += ":#{r[:role]}" if r[:role]
    end
    cmd += " loss-policy=#{@loss_policy}" if @loss_policy
    cmd
  end
end
