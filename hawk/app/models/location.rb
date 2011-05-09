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

class Location < Constraint
  @attributes = :rules, :rsc
  attr_accessor *@attributes
  
  def initialize(attributes = nil)
    @rules  = []
    @rsc    = nil
    super
  end

  def validate
    error _('Constraint is too complex - it contains nested rules') if too_complex?
  end

  def create
  end
  
  def update
  end
  
  def update_attributes(attributes = nil)
    @rules  = []
    @rsc    = nil
    super
  end

  def too_complex?
    @too_complex ||= false
  end

  class << self
    def instantiate(xml)
      con = allocate
      rules = []
      if xml.attributes['score']
        # Simple location constraint, fold to rule notation
        rules << {
          :score => xml.attributes['score'],
          :expressions => [ {
              :attribute => '#uname',
              :operation => 'eq',
              :value     => xml.attributes['node']
          } ]
        }
      else
        # Rule notation
        xml.elements.each do |rule_elem|
          rule = {
            :id               => rule_elem.attributes['id'],
            :role             => rule_elem.attributes['role'] || nil,
            :score            => rule_elem.attributes['score'] || rule_elem.attributes['score-attribute'] || nil,
            :boolean_op       => rule_elem.attributes['boolean-op'] || 'and',
            :expressions      => []
          }
          rule_elem.elements.each do |expr_elem|
            if expr_elem.name == 'rule'
              con.instance_variable_set(:@too_complex, true)
              next
            end
            rule[:expressions] << {
              :value      => expr_elem.attributes['value'] || nil,
              :attribute  => expr_elem.attributes['attribute'] || nil,
              :type       => expr_elem.attributes['type'] || 'string',
              :operation  => expr_elem.attributes['operation'] || nil
            }
          end
          rules << rule
        end
      end
      con.instance_variable_set(:@rsc,   xml.attributes['rsc'])
      con.instance_variable_set(:@rules, rules)
      con
    end
  end
end

