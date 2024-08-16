# Copyright (c) 2024 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.
require 'invoker'

class Bundle < Resource

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
      record
    end

    def cib_type
      :bundle
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
    errors.add :base, _("Editing bundles is not yet supported.")
  end

  def shell_syntax
    [].tap do |cmd|
      cmd.push "bundle #{id}"
    end.join(" ")
  end
end
