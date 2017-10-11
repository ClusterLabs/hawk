# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'invoker'

class Group < Resource
  attribute :children, Array[String]

  validate do |record|
    # TODO(must): Ensure children are sanitized
    if record.children.empty?
      # Delete previously detected errors as they are confusing,
      # but caused by not having any children (bsc#1006169)
      record.errors.delete :base
      record.errors.add :base, _("Group cannot be empty, expected at least one child")
    end
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

      record.children = xml.elements.collect("primitive") do |el|
        el.attributes["id"]
      end

      record.meta = if xml.elements["meta_attributes"]
        vals = xml.elements["meta_attributes"].elements.collect do |el|
          [
            el.attributes["name"],
            el.attributes["value"]
          ]
        end

        Hash[vals]
      else
        {}
      end

      record
    end

    def cib_type
      :group
    end

    def mapping
      # TODO(must): Are other meta attributes for clone valid?
      @mapping ||= begin
        {
          "is-managed" => {
            type: "boolean",
            default: "true",
            longdesc: _("Is the cluster allowed to start and stop the resource?")
          },
          "maintenance" => {
            type: "boolean",
            default: "false",
            longdesc: _("Resources in maintenance mode are not monitored by the cluster.")
          },
          "priority" => {
            type: "integer",
            default: "0",
            longdesc: _("If not all resources can be active, the cluster will stop lower priority resources in order to keep higher priority ones active.")
          },
          "target-role" => {
            type: "enum",
            default: "Stopped",
            values: [
              "Started",
              "Stopped",
              "Master"
            ],
            longdesc: _("What state should the cluster attempt to keep this resource in?")
          }
        }
      end
    end
  end

  protected

  def update
    unless self.class.exists?(self.id, self.class.cib_type_write)
      errors.add :base, _("The ID \"%{id}\" does not exist") % { id: self.id }
      return false
    end

    old_children = xml.elements.collect("primitive") { |el| el.attributes["id"] }
    if children != old_children
      cmd = shell_syntax
      _out, err, rc = Invoker.instance.crm_configure_load_update(cmd)
      if rc != 0
        errors.add :base, err
        false
      else
        true
      end
    else
      begin
        merge_nvpairs("meta_attributes", meta)
        Invoker.instance.cibadmin_replace xml.to_s
      rescue NotFoundError, SecurityError, RuntimeError => e
        errors.add :base, e.message
        return false
      end
    end
  end

  def shell_syntax
    [].tap do |cmd|
      cmd.push "group #{id}"

      children.each do |child|
        cmd.push child
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
