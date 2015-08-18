# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Resource < CibObject
  class << self
    def all
      # Doesn't actually work - only gets top-level resources, not
      # e.g.: primitive children of groups or clones.
      super("resources", true)
    end
  end
end

