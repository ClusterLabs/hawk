# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Primitive < Template
  attribute :template, String

  def template?
    false
  end

  def resource?
    true
  end

  class << self
    def all
      super.select do |record|
        record.class.to_s == self.to_s
      end
    end

    def instantiate(xml)
      record = super
      record.template = xml.attributes["template"] || ""

      record
    end

    def cib_type
      :primitive
    end
  end

  protected

  def update
    unless self.class.exists?(self.id, self.class.cib_type_write)
      errors.add :base, _("The ID \"%{id}\" does not exist") % { id: self.id }
      return false
    end

    begin
      merge_operations(ops)
      merge_nvpairs("instance_attributes", params)
      merge_nvpairs("meta_attributes", meta)

      Invoker.instance.cibadmin_replace xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      errors.add :base, e.message
      return false
    end

    true
  end

  def shell_syntax
    [].tap do |cmd|
      # TODO(must): Ensure clazz, provider and type are sanitized
      cmd.push "primitive #{id}"

      if template.empty?
        cmd.push [
          clazz,
          provider,
          type
        ].reject(&:nil?).reject(&:empty?).join(":")
      else
        cmd.push "@#{template}"
      end

      unless params.empty?
        cmd.push "params"

        params.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end

      unless ops.empty?
        cmd.push "params"

        ops.each do |op, instances|
          instances.each do |i, attrlist|
            cmd.push "op #{op}"

            attrlist.each do |key, value|
              cmd.push [
                key,
                value.shellescape
              ].join("=")
            end
          end
        end
      end

      unless meta.empty?
        cmd.push "meta"

        meta.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end
    end.join(" ")
  end
end
