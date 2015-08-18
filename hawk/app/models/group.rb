# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Group < Record
  attribute :id, String
  attribute :children, Array[String]
  attribute :meta, Hash, default: {}

  validates :id,
    presence: { message: _("Group ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Group ID") }

  validate do |record|
    # TODO(must): Ensure children are sanitized
    errors.add :children, _("No Group children specified") if record.children.empty?
  end

  def mapping
    self.class.mapping
  end

  class << self
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
            default: "true"
          },
          "priority" => {
            type: "integer",
            default: "0"
          },
          "target-role" => {
            type: "enum",
            default: "Started",
            values: [
              "Started",
              "Stopped",
              "Master"
            ]
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

    begin
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
