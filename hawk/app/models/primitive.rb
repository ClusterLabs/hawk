# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Primitive < Template
  attribute :template, String

  def clazz_with_template
    if template.present?
      ::Template.find(template).try(:clazz)
    else
      clazz_without_template
    end
  end

  alias_method_chain :clazz, :template

  def provider_with_template
    if template.present?
      ::Template.find(template).try(:provider)
    else
      provider_without_template
    end
  end

  alias_method_chain :provider, :template

  def type_with_template
    if template.present?
      ::Template.find(template).try(:type)
    else
      type_without_template
    end
  end

  alias_method_chain :type, :template

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
        params.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end

      unless ops.empty?
        ops.each do |_id, op|
          cmd.push "op #{op["name"]}"

          op.each do |key, value|
            next if key == "name"
            cmd.push [
              key,
              value.shellescape
            ].join("=")
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
