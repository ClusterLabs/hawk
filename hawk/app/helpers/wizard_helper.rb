# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module WizardHelper
  # Thank you http://marklunds.com/articles/one/314
  def flatten_hash(hash = params, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += "[]" if v.is_a?(Array)
        flat_hash[key] = v
      end
    end

    flat_hash
  end

  def flat_hash_key(names)
    names = Array.new(names)
    name = names.shift.to_s.dup
    names.each do |n|
      name << "[#{n}]"
    end
    name
  end

  def hash_as_hidden_fields(hash = params)
    hidden_fields = []
    flatten_hash(hash).each do |name, value|
      value = [value] if !value.is_a?(Array)
      value.each do |v|
        hidden_fields << hidden_field_tag(name, v.to_s, :id => nil)
      end
    end

    hidden_fields.join("\n")
  end

  def wizard_categories(wizards)
    wizards.map { |w| w.category }.uniq.sort
  end

  def wizard_icon(wizard)
    case wizard
    when "database"
      "database"
    when "filesystem"
      "hdd-o"
    when "server"
      "server"
    else
      "list"
    end
  end

  def shortdesc_format(text)
    if text.is_a? Hash
      text = text["__content__"] || ""
    end
    return "" if text.blank?
    return text
  end

  def longdesc_format(text)
    if text.is_a? Hash
      text = text["__content__"] || ""
    end
    return "" if text.blank?
    text.gsub!(/([^\n])\n([^\n])/, '\1 \2')
    simple_format(html_escape(text), {}, sanitize: false)
  end

  def sanitize_value(value)
    # the script code supports values that
    # we can't deal with in the UI right now
    return nil if value && value.to_s.include?('{{')
    value
  end
end
