# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'invoker'

class Primitive < Template
  attribute :template, String
  attribute :parent, String

  def clazz_with_template
    if template.present?
      ::Template.find(template).try(:clazz)
    else
      clazz_without_template
    end
  end

  alias_method :clazz_without_template, :clazz
  alias_method :clazz, :clazz_with_template

  def provider_with_template
    if template.present?
      ::Template.find(template).try(:provider)
    else
      provider_without_template
    end
  end

  alias_method :provider_without_template, :provider
  alias_method :provider, :provider_with_template

  validate :validate_params

  def validate_params
    required_params = []
    res = Hash.from_xml(Util.get_meta_data(agent_name))
    param_res = res["resource_agent"]["parameters"]["parameter"]
    if param_res
      param_res.each do |items|
        if items.key?("required") && items["required"] == "1"
          required_params << items["name"]
        end
      end
    end

    params.each do |param, value|
      if value.blank? && required_params.include?(param)
        errors.add(:base, "In Parameters, #{param}'s value is blank!")
      end
    end
  end

  def type_with_template
    if template.present?
      ::Template.find(template).try(:type)
    else
      type_without_template
    end
  end

  alias_method :type_without_template, :type
  alias_method :type, :type_with_template

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
      merge_nvpairs("utilization", utilization)
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

      cmd.push agent_name

      unless params.blank?
        params.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end

      unless ops.blank?
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

      unless meta.blank?
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
