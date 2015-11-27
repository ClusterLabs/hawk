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
    icon_tag(status_icon_name_for(type))
  end

  def status_icon_name_for(type)
    case type.to_sym
    when :ok
      "check"
    when :errors
      "exclamation-triangle"
    when :maintenance
      "wrench"
    when :nostonith
      "plug"
    else
      "question"
    end
  end
end
