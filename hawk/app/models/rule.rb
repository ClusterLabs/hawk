# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Rule < Tableless
  attr_accessor :id

  attribute :right, String, default: 'read'
  attribute :xpath, String, default: ''
  attribute :tag, String, default: ''
  attribute :ref, String, default: ''
  attribute :attribute, String, default: ''

  validates :right, presence: true
  validate :rule_combination

  def shell_syntax
    [].tap do |rule|
      rule.push @right
      rule.push crm_quote("xpath:#{@xpath}") unless @xpath.blank?
      rule.push crm_quote("tag:#{@tag}") unless @tag.blank?
      rule.push crm_quote("ref:#{@ref}") unless @ref.blank?
      rule.push crm_quote("attr:#{@attribute}") unless @attribute.blank?
    end
  end

  def rule_combination
    if [self.xpath, self.tag].reject(&:blank?).size == 0
      errors[:base] << ("At least one of xpath or object type must be set.")
    end
    if !self.xpath.blank? && (!self.tag.blank? || !self.attribute.blank?)
      errors[:base] << ("Conflicting options for rule")
    end
  end

  def save
    valid?
  end

  def new_record?
    true
  end

  private

  def crm_quote(str)
    if str.index("'")
      "\"#{str}\""
    else
      "'#{str}'"
    end
  end

end
