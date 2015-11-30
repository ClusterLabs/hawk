# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'invoker'

class Clone < Resource
  attribute :id, String
  attribute :child, String

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
            default: "true",
            longdesc: _("Is the cluster allowed to start and stop the resource?")
          },
          "priority" => {
            type: "integer",
            default: "0",
            longdesc: _("If not all resources can be active, the cluster will stop lower priority resources in order to keep higher priority ones active.")
          },
          "target-role" => {
            type: "enum",
            default: "Started",
            values: ["Started", "Stopped", "Master"],
            longdesc: _("What state should the cluster attempt to keep this resource in?")
          },
          "clone-max" => {
            type: "integer",
            default: current_cib.nodes.length.to_s,
            longdesc: _("How many copies of the resource to start. Defaults to the number of nodes in the cluster.")
          },
          "clone-node-max" => {
            type: "integer",
            default: "1",
            longdesc: _("How many copies of the resource can be started on a single node. Defaults to 1.")
          },
          "notify" => {
            type: "boolean",
            default: "false",
            longdesc: _("When stopping or starting a copy of the clone, tell all the other copies beforehand and when the action was successful.")
          },
          "globally-unique" => {
            type: "boolean",
            default: "true",
            longdesc: _("Does each copy of the clone perform a different function?")
          },
          "ordered" => {
            type: "boolean",
            default: "false",
            longdesc: _("Should the copies be started in series (instead of in parallel)?")
          },
          "interleave" => {
            type: "boolean",
            default: "false",
            longdesc: _("Changes the behavior of ordering constraints (between clones/masters) so that instances can start/stop as soon as their peer instance has (rather than waiting for every instance of the other clone has).")
          }
        }
      end
    end

    def help_text
      super.merge(
        "resource" => {
          type: "string",
          default: "",
          shortdesc: _("Child Resource"),
          longdesc: _("Child resource to use as clone.")
        }
      )
    end
  end

  protected

  def update
    # TODO(must): use crmsh for this
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
