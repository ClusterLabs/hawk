# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

class StepParameter < Tableless
  attribute :name, String
  attribute :shortdesc, String
  attribute :longdesc, String
  attribute :advanced, Boolean
  attribute :required, Boolean
  attribute :unique, Boolean
  attribute :type, String
  attribute :value, String
  attribute :example, String

  def title
    @name.gsub(/_-/, " ").titleize
  end

  def attrlist_type
    return "boolean" if @type == "boolean"
    return "integer" if @type == "integer"
    return "string"
  end
end
