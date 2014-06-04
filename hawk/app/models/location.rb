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

class Location < Constraint
  @attributes = :rules, :rsc
  attr_accessor *@attributes
  
  def initialize(attributes = nil)
    @rules  = []
    @rsc    = ['']
    super
  end

  def validate
    error _('Constraint is too complex - it contains nested rules') if too_complex?

    error _('No rules specified') if @rules.empty?

    @rsc.map{|r| r.strip!}
    @rsc.delete_if{|r| r.empty?}
    error _("No resource specified") if @rsc.empty?

    # TODO(should): break out early if there's errors - it can get quite noisy
    # otherwise if there's lots of invalid input
    @rules.each do |rule|
      rule[:score].strip!
      unless ['mandatory', 'advisory', 'inf', '-inf', 'infinity', '-infinity'].include? rule[:score].downcase
        if simple?
          unless rule[:score].match(/^-?[0-9]+$/)
            error _('Invalid score "%{score}"') % { :score => rule[:score] }
          end
        else
          # We're allowing any old junk for scores for complex resources,
          # because you're allowed to use score-attribute here.
          # TODO(must): Tighten this up if possible
        end
      end
      error _('No expressions specified') if rule[:expressions].empty?
      rule[:expressions].each do |e|
        e[:attribute].strip!
        e[:value].strip!
        error _("Attribute contains both single and double quotes") if unquotable? e[:attribute]
        error _("Value contains both single and double quotes") if unquotable? e[:value]
      end
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
    unless CibObject.exists?(id, 'rsc_location')
      error _('Constraint ID "%{id}" does not exist') % { :id => @id }
      return false
    end

    # Can just use crm configure load update here, it's trivial enough (because
    # we basically replace the object every time, rather than having to merge
    # like primitive, ms, etc.)

    # TODO(should): double-check rule id preservation (seems the shell does
    # this by magic, and we get it for free!)
    result = Invoker.instance.crm_configure_load_update shell_syntax
    unless result == true
      error _('Unable to update constraint: %{msg}') % { :msg => result }
      return false
    end

    true
  end
  
  def update_attributes(attributes = nil)
    @rules  = []
    @rsc    = ['']
    super
  end

  # Can this rule be folded back to "location <id> <res> <score>: <node>
  def simple?
    @rules.none? ||
      @rules.length == 1 && rules[0][:expressions].length == 1 &&
        (!rules[0].has_key?(:role) || rules[0][:role].empty?) &&
        rules[0][:score] && rules[0][:expressions][0][:value] &&
        rules[0][:expressions][0][:attribute] == '#uname' &&
        rules[0][:expressions][0][:operation] == 'eq'
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
        xml.elements.each('rule') do |rule_elem|
          rule = {
            :id               => rule_elem.attributes['id'],
            :role             => rule_elem.attributes['role'] || "",
            :score            => rule_elem.attributes['score'] || rule_elem.attributes['score-attribute'] || "",
            :boolean_op       => rule_elem.attributes['boolean-op'] || "",  # default behaviour is "and"
            :expressions      => []
          }
          rule_elem.elements.each do |expr_elem|
            if expr_elem.name != 'expression'
              # Considers nested rules and date_expression to be too complex
              # TODO(should): Handle date expressions
              con.instance_variable_set(:@too_complex, true)
              next
            end
            rule[:expressions] << {
              :value      => expr_elem.attributes['value'] || "",
              :attribute  => expr_elem.attributes['attribute'] || "",
              :type       => expr_elem.attributes['type'] || "",  # default behaviour is "string"
              :operation  => expr_elem.attributes['operation'] || ""
            }
          end
          rules << rule
        end
      end
      rsc = []
      if xml.attributes['rsc']
        # Single resource
        rsc << xml.attributes['rsc']
      else
        # Resource set
        xml.elements.each('resource_set') do |rsc_set|
          rsc_set.elements.each do |rsc_elem|
            rsc << rsc_elem.attributes['id']
          end
        end
      end
      con.instance_variable_set(:@rsc,   rsc)
      con.instance_variable_set(:@rules, rules)
      con
    end
  end

  private

  # TODO(must): Move this somewhere else and reuse in other models
  # TODO(should): Don't add quotes if unnecessary (e.g. no whitespace in val)
  def crm_quote(str)
    if str.index("'")
      "\"#{str}\""
    else
      "'#{str}'"
    end
  end

  # TODO(must): As above, move this elsewhere for reuse
  def unquotable?(str)
    str.index("'") && str.index('"')
  end

  # Note: caller must ensure valid rule before calling this
  def shell_syntax
    cmd = "location #{@id} "
    if @rsc.length == 1
      cmd += " #{@rsc[0]}"
    else
      cmd += " { #{@rsc.join(' ')} }"
    end

    if simple?
      cmd += " #{@rules[0][:score]}: #{@rules[0][:expressions][0][:value]}"
    else
      @rules.each do |rule|
        op = rule[:boolean_op]
        op = "and" if op == ""
        cmd += " rule"
        cmd += " $role=\"#{rule[:role]}\"" unless rule[:role].empty?
        cmd += " #{crm_quote(rule[:score])}:"
        cmd += rule[:expressions].map {|e|
          if ["defined", "not_defined"].include? e[:operation]
            " #{e[:operation]} #{crm_quote(e[:attribute])} "
          else
            " #{crm_quote(e[:attribute])} " +
              (e[:type] != "" ? "#{e[:type]}:" : "") +
            "#{e[:operation]} #{crm_quote(e[:value])} "
          end
        }.join(op)
      end
    end
    cmd
  end
end

