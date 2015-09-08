# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Clone < Resource
  attribute :id, String
  attribute :child, String
  attribute :meta, Hash, default: {}

  validates :id,
    presence: { message: _("Clone ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Clone ID") }

  validates :child,
    presence: { message: _("No Clone child specified") }

  validate do |record|
    # TODO(must): Ensure children are sanitized
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

      record.child = if xml.elements["primitive|group"]
        xml.elements["primitive|group"].attributes["id"]
      else
        nil
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
      :clone
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
          },
          "clone-max" => {
            type: "integer",
            default: %x[cibadmin -Ql --scope nodes 2>/dev/null].scan("<node ").length
          },
          "clone-node-max" => {
            type: "integer",
            default: "1"
          },
          "notify" => {
            type: "boolean",
            default: "false"
          },
          "globally-unique" => {
            type: "boolean",
            default: "true"
          },
          "ordered" => {
            type: "boolean",
            default: "false"
          },
          "interleave" => {
            type: "boolean",
            default: "false"
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
      cmd.push "clone #{id} #{child}"

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
