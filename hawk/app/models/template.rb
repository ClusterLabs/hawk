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
          clazzes = Util.safe_x('/usr/sbin/crm', 'ra', 'classes').split(/\n/)
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
            Tableless::RSC_DEFAULTS
          ),
          opmeta: Tableless::OP_DEFAULTS
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
