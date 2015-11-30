# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Role < Record
  attribute :rules, RuleCollection[Rule]
  attr_accessor :schema_version

  validates :rules, presence: { message: _('At least one rule is required') }

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
    unless rules.valid?
      rules.each do |rule|
        rule.errors.each do |key, message|
          errors.add key, message
        end
      end
    end
    super && rules.valid?
  end

  def schema_version
    @schema_version ||= Util.acl_version
  end

  protected

  def shell_syntax
    [].tap do |cmd|
      cmd.push "role #{id}"
      rules.each do |rule|
        cmd.concat rule.shell_syntax
      end
    end.join(' ')
  end

  class << self
    def instantiate(xml)
      record = allocate

      if record.schema_version >= 2.0
        xml.elements.each do |elem|
          record.rules.build(
            right: elem.attributes['kind'],
            tag: elem.attributes['object-type'] || nil,
            ref: elem.attributes['reference'] || nil,
            xpath: elem.attributes['xpath'] || nil,
            attribute: elem.attributes['attribute'] || nil
          )
        end
      else
        xml.elements.each do |elem|
          record.rules.build(
            right: elem.name,
            tag: elem.attributes['tag'] || nil,
            ref: elem.attributes['ref'] || nil,
            xpath: elem.attributes['xpath'] || nil,
            attribute: elem.attributes['attribute'] || nil
          )
        end
      end

      record
    end

    def cib_type
      :acl_role
    end
  end
end
