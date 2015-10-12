# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Tag < Resource
  attribute :id, String
  attribute :refs, Array[String]

  validates :id,
    presence: { message: _("Tag ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Tag ID") }

  validates :refs,
    presence: { message: _("No Tag resources specified") }

  def mapping
    self.class.mapping
  end

  def state
    prio = {
      unknown: 0,
      stopped: 1,
      started: 2,
      slave: 3,
      master: 4,
      pending: 5,
      failed: 6
    }
    sum_state = :unknown
    # This is a bit magic, but refs can either
    # be a list of ids or a list of actual child objects
    refs.each do |ref|
      tagged = nil
      if ref.is_a? String
        tagged = cib_by_id(ref)
      else
        tagged = cib_by_id(ref.id)
      end
      unless tagged.nil?
        rstate = tagged[:state]
        if prio[rstate] > prio[sum_state]
          sum_state = rstate
        end
      end
    end
    sum_state
  end

  class << self
    def all
      super.select do |record|
        record.is_a? self
      end
    end

    def instantiate(xml)
      record = allocate
      record.refs = xml.elements.collect("obj_ref") do |el|
        el.attributes["id"]
      end
      record
    end

    def cib_type
      :tag
    end

    def mapping
      @mapping ||= {}
    end
  end

  protected

  def update
    unless self.class.exists?(self.id, self.class.cib_type_write)
      errors.add :base, _("The ID \"%{id}\" does not exist") % { id: self.id }
      return false
    end

    begin
      Invoker.instance.cibadmin_replace xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      errors.add :base, e.message
      return false
    end

    true
  end

  def shell_syntax
    [].tap do |cmd|
      cmd.push "tag #{id}"

      refs.each do |ref|
        cmd.push ref
      end
    end.join(" ")
  end
end
