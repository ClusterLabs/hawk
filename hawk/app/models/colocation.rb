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

# Note that Colocation and Order use of the resources array is the
# inverse of each other, always, regardless of inconsistencies in
# the underlying configuraton.  e.g. (simplified):
#   order.resources = [ 'A', 'B', 'C' ];
#   colocation.resources = [ 'C', 'B', 'A' ];

class Colocation < Constraint
  
  @attributes = :score, :resources
  attr_accessor *@attributes
  
  def initialize(attributes = nil)
    @score      = nil
    @resources  = []
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
    unless CibObject.exists?(id, 'rsc_colocation')
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
    @score      = nil
    @resources  = []
    super
  end

  class << self
    def instantiate(xml)
      con = allocate
      con.instance_variable_set(:@score,  xml.attributes['score'] || nil)
      resources = []
      if xml.attributes['rsc']
        # Simple (two resource) constraint, fold to set notation
        resources << {
          :sequential => true,
          :role => xml.attributes['rsc-role'] || nil,
          :resources => [ { :id => xml.attributes['rsc'] } ]
        }
        resources << {
          :sequential => true,
          :role => xml.attributes['with-rsc-role'] || nil,
          :resources => [ { :id => xml.attributes['with-rsc'] } ]
        }
      else
        # Resource set
        xml.elements.each do |resource_set|
          set = {
            :sequential => Util.unstring(resource_set.attributes['sequential'], true),
            :role       => resource_set.attributes['role'] || nil,
            :resources  => []
          }
          resource_set.elements.each do |e|
            # For members within a set, the order is reversed (i.e. in
            # "group" order, where each resources is colocated with its
            # predecessor), so we insert it at the beginning of the set
            set[:resources].unshift({ :id => e.attributes['id'] })
          end
          # Between sets, the order is as for pairs, i.e. first with
          # second
          resources << set
        end
      end
      con.instance_variable_set(:@resources, resources)
      con
    end
  end

  private

  def shell_syntax
    cmd = "colocation #{@id} #{@score}:"

    #
    # crm syntax matches nasty inconsistency in CIB, i.e. to get:
    #
    #   d6 -> d5 -> ( d4 d3 ) -> d2 -> d1 -> d0
    #
    # you use:
    #
    #   colocation <id> <score>: d5 d6 ( d3 d4 ) d0 d1 d2
    #
    # except when using simple constrains, i.e. to get:
    #
    #   d1 -> d0
    #
    # you use:
    #
    #   colocation <id> <score>: d1 d0
    #
    # To further confuse matters, duplicate roles in complex chains
    # are collapsed to sets, so for:
    #
    #   d2:Master -> d1:Started -> d0:Started
    #
    # you use:
    #
    #   colocation <id> <score>: d2:Master d0:Started d1:Started
    #
    # To deal with this, we need to collapse all the sets first
    # then iterate through them (unlike the Order model, where
    # this is unnecessary)

    # Have to clone out of @resources, else we've just got references
    # to elements of @resources inside collapsed, which causes @resources
    # to be modified, which we *really* don't want.
    collapsed = [ @resources.first.clone ]
    @resources.last(@resources.length - 1).each do |set|
      if collapsed.last[:sequential] == set[:sequential] &&
         collapsed.last[:role] == set[:role]
        collapsed.last[:resources] += set[:resources]
      else
        collapsed << set.clone
      end
    end

    if collapsed.length == 1 && collapsed[0][:resources].length == 2
      # simple constraint (it's already in reverse order so
      # don't flip around the other way like we do below)
      collapsed[0][:resources].each do |r|
        cmd += " #{r[:id]}"
        cmd += ":#{set[:role]}" if collapsed[0][:role]
      end
    else
      collapsed.each do |set|
        cmd += " ( " unless set[:sequential]
        set[:resources].reverse.each do |r|
          cmd += " #{r[:id]}"
          cmd += ":#{set[:role]}" if set[:role]
        end
        cmd += " )" unless set[:sequential]
      end
    end
    cmd
  end
end

