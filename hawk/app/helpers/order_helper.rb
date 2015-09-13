# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module OrderHelper
  def available_order_actions
    {
      "start" => _("Start"),
      "promote" => _("Promote"),
      "demote" => _("Demote"),
      "stop" => _("Stop")
    }
  end

  def available_order_resources
    [
      @cib.resources.map(&:id),
      @cib.templates.map(&:id)
    ].flatten.sort do |a, b|
      a.natcmp(b, true)
    end
  end
end
