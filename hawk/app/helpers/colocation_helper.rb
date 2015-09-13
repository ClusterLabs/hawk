# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module ColocationHelper
  def available_colocation_roles
    {
      "Started" => _("Started"),
      "Master" => _("Master"),
      "Slave" => _("Slave"),
      "Stopped" => _("Stopped")
    }
  end

  def available_colocation_resources
    [
      @cib.resources.map(&:id),
      @cib.templates.map(&:id)
    ].flatten.sort do |a, b|
      a.natcmp(b, true)
    end
  end
end
