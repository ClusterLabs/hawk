# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Resource < Record
  class CommandError < StandardError
  end

  attribute :object_type, Symbol

  def object_type
    self.class.to_s.downcase
  end

  class << self
    def all
      super(true)
    end

    def cib_type_fetch
      :resources
    end
  end
end
