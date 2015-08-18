# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Role < Record
  attribute :id, String
  attribute :rules, RuleCollection[Rule]

  validates :id,
    presence: { message: _('Role ID is required') },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _('Invalid Role ID') }

  def initialize(*args)
    rules.build
    super
  end

  def rules_attributes=(attrs)
    @rules = RuleCollection.new

    attrs.each do |key, values|
      @rules.push Rule.new(values)
    end
  end

  def rules
    @rules ||= RuleCollection.new
  end

  def valid?
    super & rules.valid?
  end

  protected

  def shell_syntax
    [].tap do |cmd|
      cmd.push "role #{id}"

      rules.each do |rule|
        cmd.push rule.right

        cmd.push "tag:#{rule.tag}" unless rule.tag.to_s.empty?
        cmd.push "ref:#{rule.ref}" unless rule.ref.to_s.empty?
        cmd.push "xpath:#{rule.xpath}" unless rule.xpath.to_s.empty?
        cmd.push "attribute:#{rule.attribute}" unless rule.attribute.to_s.empty?
      end
    end.join(' ')
  end

  class << self
    def instantiate(xml)
      record = allocate

      xml.elements.each do |elem|
        record.rules.build(
          right: elem.attributes['kind'],
          tag: elem.attributes['object-type'] || nil,
          ref: elem.attributes['reference'] || nil,
          xpath: elem.attributes['xpath'] || nil,
          attribute: elem.attributes['attribute'] || nil
        )
      end

      record
    end

    def cib_type
      :acl_role
    end
  end
end
