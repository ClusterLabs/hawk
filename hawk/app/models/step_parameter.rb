# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

class StepParameter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :parent
  attr_accessor :name
  attr_accessor :shortdesc
  attr_accessor :longdesc
  attr_accessor :advanced
  attr_accessor :required
  attr_accessor :unique
  attr_accessor :type
  attr_accessor :value
  attr_accessor :example

  def persisted?
    false
  end

  def initialize(parent, data)
    @parent = parent
    @name = data["name"]
    @shortdesc = data["shortdesc"].strip
    @longdesc = data["longdesc"]
    @advanced = data["advanced"] || false
    @required = data["required"] || false
    @unique = data["unique"] || false
    @type = data["type"]
    @value = data["value"]
    @example = data["example"]
  end

  def id
    "#{parent.id}.#{name}"
  end

  def help_id
    id.gsub(/[.]/, "-")
  end

  def title
    @name.gsub(/[_-]/, " ").titleize
  end

  def attrlist_type
    return "boolean" if @type == "boolean"
    return "integer" if @type == "integer"
    return "string"
  end
end
