# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Constraint < Record
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

    def find(id, attr = 'id')
      rsc = super(id, attr)
      return rsc if rsc.is_a? Constraint
      raise Cib::RecordNotFound, _("Not a constraint")
    end

    def cib_type_fetch
      :constraints
    end
  end
end
