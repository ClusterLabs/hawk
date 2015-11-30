# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Location < Constraint
  attribute :resources, Array[String]
  attribute :rules, Array[Hash]
  attribute :discovery, String

  validates :resources,
    presence: { message: _("No resource specified") }

  validates :rules,
    presence: { message: _("No rules specified") }

  validate do |record|
    unless record.discovery.blank?
      unless self.class.discovery_types.include? record.discovery.downcase
        errors.add :discovery, _("Invalid resource discovery type")
      end
    end

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

      if rule[:expressions].blank?
        errors.add :base, _('No expressions specified')
      else
        rule[:expressions].each do |e|
          e[:attribute].strip!
          e[:value].to_s.strip!
          errors.add :base, _("Attribute contains both single and double quotes") if unquotable? e[:attribute]
          errors.add :base, _("Value contains both single and double quotes") if unquotable? e[:value]
        end
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
      rules[0][:expressions] &&
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

  def shell_syntax
    [].tap do |cmd|
      cmd.push "location #{id}"

      if resources.length == 1
        cmd.push resources.first
      else
        cmd.push ["{", resources.join(" "), "}"].join(" ")
      end

      cmd.push "resource-discovery=#{crm_quote(discovery)}" unless discovery.blank?

      if simple?
        cmd.push "#{rules.first[:score]}:"
        cmd.push "#{rules.first[:expressions].first[:value]}"
      else
        rules.each do |rule|
          op = rule[:boolean_op]
          op = "and" if op == ""
          cmd.push "rule"
          cmd.push "$role=#{crm_quote(rule[:role])}" unless rule[:role].empty?
          cmd.push "#{rule[:score]}:"
          cmd.push rule[:expressions].map {|e|
            if ["defined", "not_defined"].include? e[:operation]
              "#{e[:operation]} #{crm_quote(e[:attribute])}"
            elsif e[:type] == ""
              "#{crm_quote(e[:attribute])} #{e[:operation]} #{crm_quote(e[:value])}"
            else
              "#{crm_quote(e[:attribute])} #{e[:type]}:#{e[:operation]} #{crm_quote(e[:value])}"
            end
          }.join(" #{op} ")
        end
      end
    end.join(" ")
  end

  class << self
    def instantiate(xml)
      record = allocate

      record.resources = [].tap do |resources|
        if xml.attributes["rsc"]
          resources.push xml.attributes["rsc"]
        else
          xml.elements.each("resource_set") do |set|
            set.elements.each do |el|
              resources.push el.attributes["id"]
            end
          end
        end
      end

      record.discovery = xml.attributes["resource-discovery"] if xml.attributes["resource-discovery"]

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
              id: rule.attributes["id"],
              role: rule.attributes["role"] || nil,
              score: rule.attributes["score"] || rule.attributes["score-attribute"] || nil,
              boolean_op: rule.attributes["boolean-op"] || "and",
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

    def discovery_types
      ['always', 'never', 'exclusive']
    end

    def help_text
      super.merge(
        "resources" => {
          type: "string",
          shortdesc: _("Resources"),
          longdesc: _('Resources to apply the constraint to.'),
          default: "",
        },
        "score" => {
          type: "string",
          shortdesc: _("Score"),
          longdesc: _('Positive values indicate the resources should run on this node. Negative values indicate the resources should not run on this node. Values of +/- INFINITY change "should"/"should not" to "must"/"must not".'),
          default: "INFINITY",
        },
        "node" => {
          type: "string",
          shortdesc: _("Node"),
          longdesc: _("Name of a node in the cluster."),
          default: "",
        },
        "resource-discovery" => {
          type: "enum",
          default: "always",
          values: discovery_types,
          shortdesc: _("Resource Discovery"),
          longdesc: _("Controls resource discovery for the specified resource on nodes covered by the constraint. always: Always perform resource discovery (default). never: Never perform resource discovery for the specified resource on this node. This option should generally be used with a -INFINITY score. exclusive: Only perform resource discovery for the specified resource on this node.")
        },
        "role" => {
          type: "string",
          shortdesc: _("Role"),
          longdesc: _('Limits the rule to apply only when the resource is in the specified role.'),
          default: "started",
        },
        "operator" => {
          type: "string",
          shortdesc: _("Operator"),
          longdesc: _('How to combine the result of multiple expression objects. Allowed values are and and or.'),
          default: "and",
        },
        "expression" => {
          type: "string",
          shortdesc: _("Expression"),
          longdesc: _("Each rule can contain a number of expressions. The results of the expressions are combined based on the rule's boolean operator."),
          default: "",
        },
      )
    end
  end
end
