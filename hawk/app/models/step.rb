# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

class Step
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :parent
  attr_accessor :name
  attr_accessor :shortdesc
  attr_accessor :longdesc
  attr_accessor :required
  attr_accessor :parameters
  attr_accessor :steps

  def persisted?
    false
  end

  def initialize(parent, data)
    @parent = parent
    @name = data["name"] || ''
    @shortdesc = data["shortdesc"].strip
    @longdesc = data["longdesc"]
    @required = data["required"] || false
    @parameters = []
    dataparams = data["parameters"] || []
    dataparams.each do |param|
      @parameters << StepParameter.new(self, param)
    end
    @steps = []
    datasteps = data["steps"] || []
    datasteps.each do |step|
      @steps << Step.new(self, step)
    end
  end

  def id
    if name.blank?
      parent.id
    else
      "#{parent.id}.#{name}"
    end
  end

  def help_id
    id.gsub(/[.]/, "-")
  end

  def title
    if shortdesc.blank?
      @parent.title
    else
      shortdesc
    end
  end

  def basic
    parameters.select { |p| not p.advanced }
  end

  def advanced
    parameters.select { |p| p.advanced }
  end

  def params_attrlist
    m = {}
    @parameters.each do |param|
      next unless param.advanced && param.value
      m[param.id] = param.value
    end
    m
  end

  def params_mapping
    m = {}
    @parameters.each do |param|
      next unless param.advanced
      m[param.id] = {
        type: param.attrlist_type,
        default: nil,
        longdesc: param.longdesc.blank? ? param.shortdesc : param.longdesc,
        name: param.name,
        help_id: param.help_id
      }
    end
    m
  end

  def params_mapping_all
    m = {}
    @parameters.each do |param|
      m[param.id] = {
        type: param.attrlist_type,
        default: nil,
        longdesc: param.longdesc.blank? ? param.shortdesc : param.longdesc,
        name: param.name,
        help_id: param.help_id
      }
    end
    m
  end

end
