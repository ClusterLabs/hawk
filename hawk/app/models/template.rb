# coding: utf-8
# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'invoker'

class Template < Resource
  attribute :clazz, String, default: "ocf"
  attribute :provider, String
  attribute :type, String

  def mapping
    self.class.mapping
  end

  def template?
    true
  end

  def resource?
    false
  end

  def options
    self.class.options
  end

  def available_meta
    self.class.available_meta
  end

  def available_opmeta
    self.class.available_opmeta
  end

  def available_utilization
    # collect utilization mapping keys from nodes
    {}.tap do |u|
      current_cib.nodes_ordered.each do |node|
        node.utilization.keys.each do |key|
          u[key] = {
            type: "integer",
            default: "",
            longdesc: ""
          }
        end
      end
    end
  end

  class << self
    def all
      super.select do |record|
        record.class.to_s == self.to_s
      end
    end

    def instantiate(xml)
      record = allocate
      record.clazz = xml.attributes["class"] || ""
      record.provider = xml.attributes["provider"] || ""
      record.type = xml.attributes["type"] || ""

      record.params = if xml.elements["instance_attributes"]
        vals = xml.elements["instance_attributes"].elements.collect do |el|
          [
            el.attributes["name"],
            el.attributes["value"]
          ]
        end

        Hash[vals]
      else
        {}
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

      record.utilization = if xml.elements["utilization"]
        vals = xml.elements["utilization"].elements.collect do |el|
          [
            el.attributes["name"],
            el.attributes["value"]
          ]
        end

        Hash[vals]
      else
        {}
      end

      record.ops = if xml.elements["operations"]
        vals = xml.elements["operations"].elements.collect do |el|
          opname = el.attributes["name"]
          key = opname
          if opname == "monitor"
            interval = el.attributes["interval"]
            m = /([0-9]+)\s*(s|m|h)?/.match(interval)
            if m
              if m[2] == "m"
                interval = (m[1].to_i * 60).to_s
              elsif m[2] == "h"
                interval = (m[1].to_i * 60 * 60).to_s
              else
                interval = m[1]
              end
            end
            key = "#{opname}_#{interval}"
          end

          ops = el.attributes.collect do |name, value|
            next if ["id"].include? name

            [
              name,
              value
            ]
          end.compact

          if key == "monitor"
            cl = el.elements["instance_attributes/nvpair[@name=\"OCF_CHECK_LEVEL\"]"]

            ops.push [
              "OCF_CHECK_LEVEL",
              cl.attributes["value"]
            ] if cl
          end

          [
            key,
            Hash[ops]
          ]
        end

        Hash[vals]
      else
        {}
      end

      record
    end

    def cib_type
      :template
    end

    def options
      Rails.cache.fetch(:crm_ra_classes, expires_in: 2.hours) do
        {}.tap do |result|
          clazzes = %x[/usr/sbin/crm ra classes].split(/\n/)
          clazzes.delete("heartbeat") unless File.directory?("/etc/ha.d/resource.d")

          clazzes.each do |clazz|
            next if clazz.start_with?(".")
            s = clazz.split("/").map(&:strip)

            if s.length >= 2
              clazz = s[0]

              result[clazz] ||= {}
              result[clazz][""] = types(clazz: clazz)

              providers = s[1].split(" ").sort do |a, b|
                a.natcmp(b, true)
              end

              providers.each do |provider|
                next if provider.start_with?(".")
                result[clazz][provider] = types(clazz: clazz, provider: provider)
              end
            else
              result[clazz] ||= {}
              result[clazz][""] = types(clazz: clazz)
            end
          end
        end
      end
    end

    def types(params = {})
      cmd = [].tap do |cmd|
        cmd.push "/usr/sbin/crm"
        cmd.push "ra"
        cmd.push "list"

        if params[:clazz]
          cmd.push params[:clazz]
        end

        if params[:provider]
          cmd.push params[:provider]
        end
      end

      Util.safe_x(*cmd).split(/\s+/).sort do |a, b|
        a.natcmp(b, true)
      end
    end

    def available_meta
      mapping[:meta]
    end

    def available_opmeta
      mapping[:opmeta]
    end

    def mapping
      @mapping ||= begin
        {
          meta: super.merge(
            "allow-migrate" => {
              type: "boolean",
              default: "false",
              longdesc: _("Set to true if the resource agent supports the migrate action")
            },
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
            "migration-threshold" => {
              type: "integer",
              default: "0",
              longdesc: _("How many failures may occur for this resource on a node, before this node is marked ineligible to host this resource. A value of 0 indicates that this feature is disabled.")
            },
            "priority" => {
              type: "integer",
              default: "0",
              longdesc: _("If not all resources can be active, the cluster will stop lower priority resources in order to keep higher priority ones active.")
            },
            "multiple-active" => {
              type: "enum",
              default: "stop_start",
              values: ["block", "stop_only", "stop_start"],
              longdesc: _("What should the cluster do if it ever finds the resource active on more than one node?")
            },
            "failure-timeout" => {
              type: "integer",
              default: "0",
              longdesc: _("How many seconds to wait before acting as if the failure had not occurred, and potentially allowing the resource back to the node on which it failed. A value of 0 indicates that this feature is disabled.")
            },
            "resource-stickiness" => {
              type: "integer",
              default: "0",
              longdesc: _("How much does the resource prefer to stay where it is?")
            },
            "target-role" => {
              type: "enum",
              default: "Started",
              values: ["Started", "Stopped", "Master"],
              longdesc: _("What state should the cluster attempt to keep this resource in?")
            },
            "restart-type" => {
              type: "enum",
              default: "ignore",
              values: ["ignore", "restart"]
            },
            "description" => {
              type: "string",
              default: ""
            },
            "requires" => {
              type: "enum",
              default: "fencing",
              values: ["nothing", "quorum", "fencing"],
              longdesc: _("Conditions under which the resource can be started.")
            },
            "remote-node" => {
              type: "string",
              default: "",
              longdesc: _("The name of the remote-node this resource defines. This both enables the resource as a remote-node and defines the unique name used to identify the remote-node. If no other parameters are set, this value will also be assumed as the hostname to connect to at the port specified by remote-port. WARNING: This value cannot overlap with any resource or node IDs. If not specified, this feature is disabled.")
            },
            "remote-port" => {
              type: "integer",
              default: 3121,
              longdesc: _("Port to use for the guest connection to pacemaker_remote.")
            },
            "remote-addr" => {
              type: "string",
              default: "",
              longdesc: _("The IP address or hostname to connect to if remote-node's name is not the hostname of the guest.")
            },
            "remote-connect-timeout" => {
              type: "string",
              default: "60s",
              longdesc: _("How long before a pending guest connection will time out.")
            }
          ),
          opmeta: {
            "interval" => {
              type: "string",
              default: 0,
              required: false,
              longdesc: _("How frequently (in seconds) to perform the operation.")
            },
            "timeout" => {
              type: "string",
              default: "0",
              required: true,
              longdesc: _("How long to wait before declaring the action has failed.")
            },
            "requires" => {
              type: "enum",
              default: "fencing",
              values: [
                "nothing",
                "quorum",
                "fencing"
              ],
              longdesc: _("What conditions need to be satisfied before this action occurs.")
            },
            "enabled" => {
              type: "boolean",
              default: "true",
              longdesc: _("If false, the operation is treated as if it does not exist.")
            },
            "role" => {
              type: "enum",
              default: "",
              values: [
                "Stopped",
                "Started",
                "Slave",
                "Master"
              ],
              longdesc: _("This option only makes sense for recurring operations. It restricts the operation to a specific role. The truly paranoid can even specify role=Stopped which allows the cluster to detect an admin that manually started cluster services.")
            },
            "on-fail" => {
              type: "enum",
              default: "stop",
              values: [
                "ignore",
                "block",
                "stop",
                "restart",
                "standby",
                "fence"
              ],
              longdesc: _("The action to take if this action ever fails.")
            },
            "start-delay" => {
              type: "string",
              default: "0"
            },
            "interval-origin" => {
              type: "string",
              default: "",
              longdesc: _("The start time of action interval. Follow the ISO8601 standard.")
            },
            "record-pending" => {
              type: "boolean",
              default: "false",
              longdesc: _("If true, the intention to perform the operation is recorded so that GUIs and CLI tools can indicate that an operation is in progress.")
            },
            "description" => {
              type: "string",
              default: ""
            }
          }
        }
      end
    end

    def help_text
      super.merge(
        "template" => {
          type: "string",
          default: "",
          shortdesc: _("Template"),
          longdesc: _("Resource template to inherit from.")
        },
        "clazz" => {
          type: "string",
          default: "",
          shortdesc: _("Class"),
          longdesc: _("Standard which the resource agent conforms to.")
        },
        "provider" => {
          type: "string",
          default: "",
          shortdesc: _("Provider"),
          longdesc: _("Vendor or project which provided the resource agent.")
        },
        "type" => {
          type: "string",
          default: "",
          shortdesc: _("Type"),
          longdesc: _("Resource agent name.")
        },
        "op-start" => {
          type: "string",
          default: "",
          shortdesc: _("Start"),
          longdesc: _("After the specified timeout period, the operation will be treated as failed.")
        },
        "op-stop" => {
          type: "string",
          default: "",
          shortdesc: _("Stop"),
          longdesc: _("After the specified timeout period, the operation will be treated as failed.")
        },
        "op-monitor" => {
          type: "string",
          default: "",
          shortdesc: _("Monitor"),
          longdesc: _("Define a monitor operation to instruct the cluster to ensure that the resource is still healthy.")
        },
      )
    end
  end

  def agent_name
    [clazz, provider, type].reject(&:blank?).join(":")
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
      cmd.push "rsc_template #{id}"

      cmd.push agent_name

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
