# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Template < Resource
  attribute :id, String
  attribute :clazz, String, default: "ocf"
  attribute :provider, String
  attribute :type, String
  attribute :ops, Hash, default: {}
  attribute :params, Hash, default: {}
  attribute :meta, Hash, default: {}

  validates :id,
    presence: { message: _("Resource ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Resource ID") }

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

  def available_meta(opts = {})
    self.class.available_params opts
  end

  def available_params(opts = {})
    self.class.available_params opts
  end

  def available_ops(opts = {})
    self.class.available_ops opts
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

      record.ops = if xml.elements["operations"]
        # ops = {}
        # xml.elements['operations'].elements.each do |e|
        #   name = e.attributes['name']
        #   ops[name] = [] unless ops[name]
        #   op = Hash[e.attributes.collect{|a| a.to_a}]
        #   op.delete 'name'
        #   op.delete 'id'
        #   if name == "monitor"
        #     # special case for OCF_CHECK_LEVEL
        #     cl = e.elements['instance_attributes/nvpair[@name="OCF_CHECK_LEVEL"]']
        #     op["OCF_CHECK_LEVEL"] = cl.attributes['value'] if cl
        #   end
        #   ops[name].push op
        # end
        # ops

        vals = xml.elements["operations"].elements.collect do |el|
          key = el.attributes["name"]

          ops = el.attributes.collect do |name, value|
            next if ["id", "name"].include? name

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

    def available_meta(params = {})
      mapping[:meta]
    end

    def available_params(params = {})
      path = [
        params[:clazz],
        params[:provider],
        params[:type]
      ].compact.reject(&:empty?).join(":")

      xml = REXML::Document.new(
        Util.safe_x(
          "/usr/sbin/crm_resource",
          "--show-metadata",
          path
        )
      )

      return {} unless xml.root

      {}.tap do |result|
        xml.elements.each("//parameter") do |el|
          name = el.attributes["name"]

          shortdesc = if el.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"]
            el.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"].text || ""
          elsif el.elements["shortdesc"]
            el.elements["shortdesc"].text || ""
          end

          longdesc = if el.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"]
            el.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"].text || ""
          elsif el.elements["longdesc"]
            el.elements["longdesc"].text || ""
          end

          result[name] = {
            shortdesc: shortdesc,
            longdesc: longdesc,
            type: el.elements["content"].attributes["type"],
            default: el.elements["content"].attributes["default"],
            required: el.attributes["required"].to_i == 1 ? true : false
          }
        end
      end
    end

    def available_ops(params = {})
      path = [
        params[:clazz],
        params[:provider],
        params[:type]
      ].compact.reject(&:empty?).join(":")

      xml = REXML::Document.new(
        Util.safe_x(
          "/usr/sbin/crm_resource",
          "--show-metadata",
          path
        )
      )

      return {} unless xml.root

      {}.tap do |result|
        xml.elements.each("//action") do |el|
          name = el.attributes["name"]

          available = Hash[el.attributes.collect { |a| a.to_a }]
          available.delete "name"
          available.delete "depth"

          ops = {}.tap do |result|
            available.each do |key, default|
              result[key] = {
                type: "string",
                default: default
              }
            end
          end

          if name == "monitor"
            unless ops.has_key?("interval")
              key = "interval"
              ops[key] ||= {}
              ops[key][:default] = "20"
              ops[key][:required] = true
            end

            key = "OCF_CHECK_LEVEL"
            ops[key] ||= {}
            ops[key][:default] = "0"
            ops[key][:type] = "string"
          end

          result[name] ||= {
            "interval" => {
              type: "string",
              default: 0,
              required: false
            },
            "timeout" => {
              type: "string",
              default: "0",
              required: true
            },
            "requires" => {
              type: "enum",
              default: "fencing",
              values: [
                "nothing",
                "quorum",
                "fencing"
              ]
            },
            "enabled" => {
              type: "boolean",
              default: "true"
            },
            "role" => {
              type: "enum",
              default: "",
              values: [
                "Stopped",
                "Started",
                "Slave",
                "Master"
              ]
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
              ]
            },
            "start-delay" => {
              type: "string",
              default: "0"
            },
            "interval-origin" => {
              type: "string",
              default: "0"
            },
            "record-pending" => {
              type: "boolean",
              default: "false"
            },
            "description" => {
              type: "string",
              default: ""
            }
          }

          result[name].merge! ops
        end
      end
    end

    def mapping
      @mapping ||= begin
        {
          meta: {
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
              default: "false"
            },
            "interval-origin" => {
              type: "integer",
              default: "0"
            },
            "migration-threshold" => {
              type: "integer",
              default: "0",
              longdesc: _("How many failures may occur for this resource on a node, before this node is marked ineligible to host this resource. A value of INFINITY indicates that this feature is disabled.")
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
      cmd.push "rsc_template #{id}"

      cmd.push [
        clazz,
        provider,
        type
      ].reject(&:nil?).reject(&:empty?).join(":")

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
