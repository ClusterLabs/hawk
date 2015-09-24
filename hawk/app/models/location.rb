# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

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

    record.rules.each do |rule|
      rule[:score].strip!

      unless score_types.include? rule[:score].downcase
        if record.simple?
          unless rule[:score].match(/^-?[0-9]+$/)
            errors.add :base, _('Invalid score "%{score}"') % { :score => rule[:score] }
          end
        else
          # We're allowing any old junk for scores for complex resources,
          # because you're allowed to use score-attribute here.
          # TODO(must): Tighten this up if possible
        end
      end

      errors.add :base, _('No expressions specified') if rule[:expressions].empty?

      rule[:expressions].each do |e|
        e[:attribute].strip!
        e[:value].to_s.strip!
        errors.add :base, _("Attribute contains both single and double quotes") if unquotable? e[:attribute]
        errors.add :base, _("Value contains both single and double quotes") if unquotable? e[:value]
      end
    end
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

  def score_types
    ['mandatory', 'advisory', 'inf', '-inf', 'infinity', '-infinity']
  end

  def crm_quote(str)
    if str.index("'")
      "\"#{str}\""
    else
      "'#{str}'"
    end
  end

  def unquotable?(str)
    str.to_s.index("'") && str.to_s.index('"')
  end

  def shell_syntax
    [].tap do |cmd|
      cmd.push "location #{id}"

      if resource.length == 1
        cmd.push resource.first
      else
        cmd.push ["{", resource.join(" "), "}"].join(" ")
      end

      if simple?
        cmd.push "#{rules.first[:score]}: #{rules.first[:expressions].first[:value]}"
      else
        rules.each do |rule|
          op = rule[:boolean_op]
          op = "and" if op == ""
          cmd.push "rule"
          cmd.push "$role=\"#{rule[:role]}\"" unless rule[:role].empty?
          cmd.push "#{crm_quote(rule[:score])}:"
          cmd.push rule[:expressions].map {|e|
            if ["defined", "not_defined"].include? e[:operation]
              "#{e[:operation]} #{crm_quote(e[:attribute])}"
            elsif e[:type] == ""
              "#{crm_quote(e[:attribute])} #{e[:operation]} #{crm_quote(e[:value])}"
            else
              "#{crm_quote(e[:attribute])} #{e[:type]}: #{e[:operation]} #{crm_quote(e[:value])}"
            end
          }.join(" #{op} ")
        end
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
          # Simple location constraint, fold to rule notation
          rules.push(
            score: xml.attributes["score"],
            expressions: [
              {
                attribute: "#uname",
                operation: "eq",
                value: xml.attributes["node"],
                kind: "uname"
              }
            ]
          )
        else
          # Rule notation
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
                # Considers nested rules and date_expression to be too complex
                # TODO(should): Handle date expressions
                record.complex = true
                next
              end

              kind = if ["not_defined", "defined"].include? el.attributes["operation"]
                       "attr-def"
                     else
                       if el.attributes["attribute"].starts_with? "#"
                         "uname"
                       else
                         "attr-val"
                       end
                     end

              set[:expressions].push(
                value: el.attributes["value"] || nil,
                attribute: el.attributes["attribute"] || nil,
                type: el.attributes["type"] || "string",
                operation: el.attributes["operation"] || nil,
                kind: kind
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
