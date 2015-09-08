# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Tag < Resource
  attribute :id, String
  attribute :refs, Array[String]

  validates :id,
    presence: { message: _("Tag ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Tag ID") }

  validate do |record|
    # TODO(must): Ensure refs are sanitized
    errors.add :refs, _("No Tag resources specified") if record.refs.empty?
  end


  def mapping
    self.class.mapping
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
