# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module CloneHelper
  def clone_child_list
    @cib.resources.select do |r|
      !r.key?(:children) || (r.key?(:children) && r[:type] == "group")
    end.map(&:id).sort do |a, b|
      a.natcmp(b, true)
    end
  end

  def clone_child_for(clone)
    if clone.child
      clone_child_list.push(clone.child).sort
    else
      clone_child_list.sort
    end
  end
end
