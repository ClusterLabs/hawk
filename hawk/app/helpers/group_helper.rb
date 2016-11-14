# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module GroupHelper
  def group_children_list
    @cib.resources.select { |r| !r.key?(:children) }.map { |x| x[:id] }.sort { |a, b| a.natcmp(b, true) }
  end

  def group_children_for(group)
    ch = []
    ch = ch.push(group.children).flatten if group.children
    group_children_list.each {|child| ch.push(child) if !ch.include? child}
    ch
  end
end
