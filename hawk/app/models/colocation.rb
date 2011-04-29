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
  
  def create
  end
  
  def update
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
end

