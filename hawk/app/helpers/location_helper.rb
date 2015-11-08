# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module LocationHelper
  def location_resource_options(selected)
    available = [
      @cib.resources.map(&:id)
    ].flatten.uniq.sort do |a, b|
      a.natcmp(b, true)
    end

    options_for_select(
      available,
      selected
    )
  end

  def location_node_options(selected)
    available = [
      @cib.nodes.map(&:id)
    ].flatten.uniq.sort do |a, b|
      a.natcmp(b, true)
    end
    options_for_select(
      available,
      selected
    )
  end

  def location_discovery_options(selected)
    options_for_select(
      ["always", "never", "exclusive"],
      selected
    )
  end
end
