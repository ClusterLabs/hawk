# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module GroupHelper
  def group_children_list
    @cib.resources.select { |r| !r.key?(:children) }.map(&:id).sort { |a, b| a.natcmp(b, true) }
  end

  def group_children_for(group)
    if group.children
      group_children_list.push(group.children).flatten
    else
      group_children_list
    end
  end
end
