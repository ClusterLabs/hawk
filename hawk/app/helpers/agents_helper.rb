# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module AgentsHelper
  def agent_name
    resource_agent = @agent["resource_agent"]
    return "" unless resource_agent
    resource_agent["name"] || ""
  end

  def agent_shortdesc
    resource_agent = @agent["resource_agent"]
    return "" unless resource_agent
    resource_agent["shortdesc"] || ""
  end

  def agent_longdesc
    resource_agent = @agent["resource_agent"]
    return "" unless resource_agent
    resource_agent["longdesc"] || ""
  end

  def agent_parameters
    resource_agent = @agent["resource_agent"]
    return [] unless resource_agent
    parameters = resource_agent["parameters"]
    return [] unless parameters
    return [] unless parameters.is_a? Hash
    parameter = parameters["parameter"]
    return [] unless parameter
    if parameter.is_a? Hash
      [parameter]
    elsif parameter.is_a? Array
      parameter
    else
      []
    end
  end

  def agent_actions
    resource_agent = @agent["resource_agent"]
    return [] unless resource_agent
    actions = resource_agent["actions"]
    return [] unless actions
    return [] unless actions.is_a? Hash
    action = actions["action"]
    return [] unless action
    if action.is_a? Hash
      [action]
    elsif action.is_a? Array
      action
    else
      []
    end
  end

  def parameter_options(p)
    [].tap do |ret|
      ret.push _("Required") if p["required"] == "1"
      ret.push _("Unique") if p["unique"] == "1"
    end.join(", ")
  end

end
