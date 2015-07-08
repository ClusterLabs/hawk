# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

class Step < Tableless
  attribute :name, String
  attribute :shortdesc, String
  attribute :longdesc, String
  attribute :required, Boolean
  attribute :parameters, Array[StepParameter]
  attribute :steps, Array[Step]

  def initialize(attrs)
    super(attrs)
  end

  def flattened_steps
    ret = []
    @steps.each do |step|
      ret << step unless step.parameters.empty?
      ret.concat step.flattened_steps
    end
    ret
  end

  def id
    @name || "parameters"
  end

  def title
    @name || _("Parameters")
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
      m[param.name] = param.value
    end
    m
  end

  def params_mapping
    m = {}
    @parameters.each do |param|
      next unless param.advanced
      m[param.name] = {
        type: param.attrlist_type,
        default: param.value || param.example
      }
    end
    m
  end
end
