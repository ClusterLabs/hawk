#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011-2013 SUSE LLC, All Rights Reserved.
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

=begin

resources =
[
  { :id => 'd0', action => 'start' },
  { :id => 'd1', action => 'promote' }
]

no, we always fold to set structure

resources =
[
  {
    :resources => [ { :id => 'd6' } ]
  },
  {
    :sequential => false,
    :resources = [ { :id => 'd1' }, { :id => 'd2' } ]
  },
  {
    :resources => [ { :id => 'd3' } ]
  }
]

=end

# Note that Colocation and Order use of the resources array is the
# inverse of each other, always, regardless of inconsistencies in
# the underlying configuraton.  e.g. (simplified):
#   order.resources = [ 'A', 'B', 'C' ];
#   colocation.resources = [ 'C', 'B', 'A' ];

class Order < Constraint
  @attributes = :score, :resources, :symmetrical
  attr_accessor *@attributes
  
  def initialize(attributes = nil)
    @score        = nil
    @resources    = []
    @symmetrical  = true
    super
  end

  def validate
    @score.strip!
    unless ['mandatory', 'advisory', 'inf', '-inf', 'infinity', '-infinity'].include? @score.downcase
      unless @score.match(/^-?[0-9]+$/)
        error _('Invalid score')
      end
    end
    if @resources.length < 2
      error _('Constraint must consist of at least two separate resources')
    end
  end

  def create
    if CibObject.exists?(id)
      error _('The ID "%{id}" is already in use') % { :id => @id }
      return false
    end

    cmd = shell_syntax
    cmd += "\ncommit\n"

    result = Invoker.instance.crm_configure cmd
    unless result == true
      error _('Unable to create constraint: %{msg}') % { :msg => result }
      return false
    end

    true
  end
  
  def update
    unless CibObject.exists?(id, 'rsc_order')
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
    @score        = nil
    @resources    = []
    @symmetrical  = true
    super
  end

  class << self
    def instantiate(xml)
      con = allocate
      con.instance_variable_set(:@score,  xml.attributes['score'] || nil)
      resources = []
      if xml.attributes['first']
        # Simple (two resource) constraint, fold to set notation
        resources << {
          :sequential => true,
          :action => xml.attributes['first-action'] || nil,
          :resources => [ { :id => xml.attributes['first'] } ]
        }
        resources << {
          :sequential => true,
          :action => xml.attributes['then-action'] || nil,
          :resources => [ { :id => xml.attributes['then'] } ]
        }
      else
        # Resource set
        xml.elements.each do |resource_set|
          set = {
            :sequential => Util.unstring(resource_set.attributes['sequential'], true),
            :action     => resource_set.attributes['action'] || nil,
            :resources  => []
          }
          resource_set.elements.each do |e|
            set[:resources] << { :id => e.attributes['id'] }
          end
          resources << set
        end
      end
      con.instance_variable_set(:@resources, resources)
      con.instance_variable_set(:@symmetrical, Util.unstring(xml.attributes['symmetrical'], true))
      con
    end
  end

  private

  def shell_syntax
    cmd = "order #{@id} #{@score}:"
    @resources.each do |set|
      cmd += " ( " unless set[:sequential]
      set[:resources].each do |r|
        cmd += " #{r[:id]}"
        cmd += ":#{set[:action]}" if set[:action]
      end
      cmd += " )" unless set[:sequential]
    end
    cmd += " symmetrical=false" unless @symmetrical
    cmd
  end
end

