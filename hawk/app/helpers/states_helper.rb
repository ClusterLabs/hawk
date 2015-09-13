# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module StatesHelper
  def status_class_for(type)
    case type.to_sym
    when :ok
      "circle-success"
    when :errors
      "circle-danger"
    when :maintenance
      "circle-info"
    when :nostonith
      "circle-warning"
    else
      "circle-warning"
    end
  end

  def status_icon_for(type)
    case type.to_sym
    when :ok
      icon_tag("check")
    when :errors
      icon_tag("exclamation-triangle")
    when :maintenance
      icon_tag("wrench")
    when :nostonith
      icon_tag("plug")
    else
      icon_tag("question")
    end
  end
end
