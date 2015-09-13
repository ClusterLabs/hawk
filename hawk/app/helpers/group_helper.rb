# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module GroupHelper
  def group_children_list
    options = @cib.resources.select do |r|
      !r.key?(:children)
    end.map(&:id).sort do |a, b|
      a.natcmp(b, true)
    end
  end

  def group_children_for(group)
    if group.children
      group_children_list.push(group.children).flatten.sort
    else
      group_children_list.sort
    end
  end
end
