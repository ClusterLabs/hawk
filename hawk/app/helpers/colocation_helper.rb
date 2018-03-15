# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module ColocationHelper
  def available_colocation_roles
    {
      "Started" => _("Started"),
      "Master" => _("Promoted"),
      "Slave" => _("Promotable"),
      "Stopped" => _("Stopped")
    }
  end

  def available_colocation_resources
    [
      @cib.resources.map{|x| x[:id]},
      @cib.templates.map{|x| x[:id]}
    ].flatten.sort do |a, b|
      a.natcmp(b, true)
    end
  end
end
