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

class Location < Constraint
  attribute :id, String
  attribute :resource, Array[String]
  attribute :rules, Array[Hash]

  validates :id,
    presence: { message: _("Constraint ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Constraint ID") }

  validates :resource,
    presence: { message: _("No resource specified") }

  validates :rules,
    presence: { message: _("No rules specified") }

  validate do |record|
    if record.complex?
      errors.add :base, _("Constraint is too complex - it contains nested rules")
      return false
    end

    # @rules.each do |rule|
    #   rule[:score].strip!
    #   unless ['mandatory', 'advisory', 'inf', '-inf', 'infinity', '-infinity'].include? rule[:score].downcase
    #     if simple?
    #       unless rule[:score].match(/^-?[0-9]+$/)
    #         error _('Invalid score "%{score}"') % { :score => rule[:score] }
    #       end
    #     else
    #       # We're allowing any old junk for scores for complex resources,
    #       # because you're allowed to use score-attribute here.
    #       # TODO(must): Tighten this up if possible
    #     end
    #   end
    #   error _('No expressions specified') if rule[:expressions].empty?
    #   rule[:expressions].each do |e|
    #     e[:attribute].strip!
    #     e[:value].strip!
    #     error _("Attribute contains both single and double quotes") if e[:attribute].index("'") && e[:attribute].index('"')
    #     error _("Value contains both single and double quotes") if e[:value].index("'") && e[:value].index('"')
    #   end
    # end
  end

  def rules
    @rules ||= []
  end

  def rules=(value)
    @rules = value
  end

  def simple?
    rules.none? ||
      rules.length == 1 &&
      rules[0][:expressions].length == 1 &&
      (!rules[0].has_key?(:role) || rules[0][:role].empty?) &&
      rules[0][:score] &&
      rules[0][:expressions][0][:value] &&
      rules[0][:expressions][0][:attribute] == '#uname' &&
      rules[0][:expressions][0][:operation] == 'eq'
  end

  def complex?
    @complex ||= false
  end

  def complex=(value)
    @complex = value
  end

  class << self
    def all
      super.select do |record|
        record.is_a? self
      end
    end
  end

  protected

  def shell_syntax



    raise "Seems to be valid!".inspect



    [].tap do |cmd|
      cmd.push "location #{id}"

      if resource.length == 1
        cmd.push resource.first
      else
        cmd.push [
          "{",
          resource.join(" "),
          "}"
        ].join(" ")
      end

      if simple?
        cmd.push [
          rules.first.score,
          rules.first.expressions.first.value
        ].join(": ")
      else





        # def crm_quote(str)
        #   if str.index("'")
        #     "\"#{str}\""
        #   else
        #     "'#{str}'"
        #   end
        # end

        # @rules.each do |rule|
        #   op = rule[:boolean_op]
        #   op = "and" if op == ""
        #   cmd += " rule"
        #   cmd += " $role=\"#{rule[:role]}\"" unless rule[:role].empty?
        #   cmd += " #{crm_quote(rule[:score])}:"
        #   cmd += rule[:expressions].map {|e|
        #     if ["defined", "not_defined"].include? e[:operation]
        #       " #{e[:operation]} #{crm_quote(e[:attribute])} "
        #     else
        #       " #{crm_quote(e[:attribute])} " +
        #         (e[:type] != "" ? "#{e[:type]}:" : "") +
        #       "#{e[:operation]} #{crm_quote(e[:value])} "
        #     end
        #   }.join(op)
        # end





      end
    end.join(" ")
  end

  class << self
    def instantiate(xml)
      record = allocate

      record.resource = [].tap do |resource|
        if xml.attributes["rsc"]
          resource.push xml.attributes["rsc"]
        else
          xml.elements.each("resource_set") do |set|
            set.elements.each do |el|
              resource.push el.attributes["id"]
            end
          end
        end
      end

      record.rules = [].tap do |rules|
        if xml.attributes["score"]
          rules.push(
            score: xml.attributes["score"],
            expressions: [
              {
                attribute: "#uname",
                operation: "eq",
                value: xml.attributes["node"]
              }
            ]
          )
        else
          xml.elements.each("rule") do |rule|
            set = {
              id: rule_elem.attributes["id"],
              role: rule_elem.attributes["role"] || nil,
              score: rule_elem.attributes["score"] || rule_elem.attributes["score-attribute"] || nil,
              boolean_op: rule_elem.attributes["boolean-op"] || "and",
              expressions: []
            }

            rule.elements.each do |el|
              if el.name != "expression"
                # TODO(should): Handle date expressions
                record.complex = true

                next
              end

              set[:expressions].push(
                value: el.attributes["value"] || nil,
                attribute: el.attributes["attribute"] || nil,
                type: el.attributes["type"] || "string",
                operation: el.attributes["operation"] || nil
              )
            end

            rules.push set
          end
        end
      end

      record
    end

    def cib_type_write
      :rsc_location
    end
  end
end
