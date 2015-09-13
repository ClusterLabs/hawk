# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module MasterHelper
  def master_child_list
    options = @cib.resources.select do |r|
      !r.key?(:children) || (r.key?(:children) && r[:type] == "group")
    end.map(&:id).sort do |a, b|
      a.natcmp(b, true)
    end
  end

  def master_child_for(master)
    if master.child
      master_child_list.push(master.child).sort
    else
      master_child_list.sort
    end
  end
end
