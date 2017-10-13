# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class CrmConfig < Tableless
  RSC_DEFAULTS = {
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
    "interval-origin" => {
      type: "integer",
      default: "0"
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
  }.freeze

  OP_DEFAULTS = {
    "interval" => {
      type: "string",
      default: 0
    },
    "timeout" => {
      type: "string",
      default: "20"
    },
    "requires" => {
      type: "enum",
      default: "fencing",
      values: ["nothing", "quorum", "fencing"],
      longdesc: _("Conditions under which the resource can be started.")
    },
    "enabled" => {
      type: "boolean",
      default: "true"
    },
    "role" => {
      type: "enum",
      default: "",
      values: ["Stopped", "Started", "Slave", "Master"]
    },
    "on-fail" => {
      type: "enum",
      default: "stop",
      values: ["ignore", "block", "stop", "restart", "standby", "fence"]
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
  }.freeze

  attribute :crm_config, Hash, default: {}
  attribute :rsc_defaults, Hash, default: {}
  attribute :op_defaults, Hash, default: {}

  def initialize(*args)
    super
    load!
  end

  def maplist(key, include_readonly = false, include_advanced = false)
    case
    when include_readonly && include_advanced
      mapping[key]
    when !include_readonly && include_advanced
      mapping[key].reject do |key, attrs|
        attrs[:readonly]
      end
    when include_readonly && !include_advanced
      mapping[key].reject do |key, attrs|
        attrs[:advanced]
      end
    else
      mapping[key].reject do |key, attrs|
        attrs[:readonly] || attrs[:advanced]
      end
    end
  end

  def mapping
    self.class.mapping
  end

  def help_text(options)
    options.map { |key| mapping[key] }.reduce(Hash.new, :merge)
  end

  def new_record?
    false
  end

  def persisted?
    true
  end

  class << self
    def mapping
      @mapping ||= begin
        {
          rsc_defaults: RSC_DEFAULTS,
          op_defaults: OP_DEFAULTS,
          crm_config: {}.tap do |crm_config|
            [
              "pengine",
              "crmd",
              "cib"
            ].each do |cmd|
              [
                "/usr/libexec/pacemaker/#{cmd}",
                "/usr/lib64/pacemaker/#{cmd}",
                "/usr/lib/pacemaker/#{cmd}",
                "/usr/lib64/heartbeat/#{cmd}",
                "/usr/lib/heartbeat/#{cmd}"
              ].each do |path|
                next unless File.executable? path

                REXML::Document.new(%x[#{path} metadata 2>/dev/null]).tap do |xml|
                  return unless xml.root

                  xml.elements.each("//parameter") do |param|
                    name = param.attributes["name"]
                    content = param.elements["content"]
                    shortdesc = param.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"].text || ""
                    longdesc  = param.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"].text || ""

                    type = content.attributes["type"]
                    default = content.attributes["default"]

                    advanced = shortdesc.match(/advanced use only/i) || longdesc.match(/advanced use only/i)

                    crm_config[name] = {
                      type: content.attributes["type"],
                      readonly: false,
                      shortdesc: shortdesc,
                      longdesc: longdesc,
                      advanced: advanced ? true : false,
                      default: default
                    }

                    if type == "enum"
                      match = longdesc.match(/Allowed values:(.*)/i)

                      if match
                        values = match[1].split(",").map do |value|
                          value.strip
                        end.reject do |value|
                          value.empty?
                        end

                        crm_config[name][:values] = values unless values.empty?
                      end
                    end
                  end
                end

                break
              end
            end

            [
              "cluster-infrastructure",
              "dc-version",
              "expected-quorum-votes",
              "have-watchdog",
            ].each do |key|
              crm_config[key][:readonly] = true if crm_config[key]
            end
          end
        }.freeze
      end
    end
  end

  protected

  def crm_config_xpath
    @crm_config_xpath ||= "//crm_config/cluster_property_set[@id='cib-bootstrap-options']"
  end

  def crm_config_value
    @crm_config_value ||= current_cib.first crm_config_xpath
  end

  def rsc_defaults_xpath
    @rsc_defaults_xpath ||= "//rsc_defaults/meta_attributes[@id='rsc-options']"
  end

  def rsc_defaults_value
    @rsc_defaults_value ||= current_cib.first rsc_defaults_xpath
  end

  def op_defaults_xpath
    @op_defaults_xpath ||= "//op_defaults/meta_attributes[@id='op-options']"
  end

  def op_defaults_value
    @op_defaults_value ||= current_cib.first op_defaults_xpath
  end

  def current_crm_config
    {}.tap do |current|
      crm_config_value.elements.each("nvpair") do |nv|
        next if mapping[:crm_config][nv.attributes["name"]].nil?
        current[nv.attributes["name"]] = nv.attributes["value"]
      end if crm_config_value
    end
  end

  def current_rsc_defaults
    {}.tap do |current|
      rsc_defaults_value.elements.each("nvpair") do |nv|
        next if mapping[:rsc_defaults][nv.attributes["name"]].nil?
        current[nv.attributes["name"]] = nv.attributes["value"]
      end if rsc_defaults_value
    end
  end

  def current_op_defaults
    {}.tap do |current|
      op_defaults_value.elements.each("nvpair") do |nv|
        next if mapping[:op_defaults][nv.attributes["name"]].nil?
        current[nv.attributes["name"]] = nv.attributes["value"]
      end if op_defaults_value
    end
  end

  def load!
    self.crm_config = current_crm_config
    self.rsc_defaults = current_rsc_defaults
    self.op_defaults = current_op_defaults
  end

  def persist!
    writer = {
      crm_config: {},
      rsc_defaults: {},
      op_defaults: {},
    }

    crm_config.diff(current_crm_config).each do |key, change|
      next unless maplist(:crm_config).keys.include? key
      new_value, old_value = change

      if new_value.nil? || new_value.empty?
        Invoker.instance.run("crm_attribute", "--attr-name", key, "--delete-attr")
      else
        writer[:crm_config][key] = new_value
      end
    end

    rsc_defaults.diff(current_rsc_defaults).each do |key, change|
      next unless maplist(:rsc_defaults).keys.include? key
      new_value, old_value = change

      if new_value.nil? || new_value.empty?
        Invoker.instance.run("crm_attribute", "--type", "rsc_defaults", "--attr-name", key, "--delete-attr")
      else
        writer[:rsc_defaults][key] = new_value
      end
    end

    op_defaults.diff(current_op_defaults).each do |key, change|
      next unless maplist(:op_defaults).keys.include? key
      new_value, old_value = change

      if new_value.nil? || new_value.empty?
        Invoker.instance.run("crm_attribute", "--type", "op_defaults", "--attr-name", key, "--delete-attr")
      else
        writer[:op_defaults][key] = new_value
      end
    end

    cmd = [].tap do |cmd|
      writer.each do |section, values|
        next if values.empty?

        case section
        when :crm_config
          cmd.push "property $id=\"cib-bootstrap-options\""
        when :rsc_defaults
          cmd.push "rsc_defaults $id=\"rsc-options\""
        when :op_defaults
          cmd.push "op_defaults $id=\"op-options\""
        end

        values.each do |key, value|
          cmd.push [
            key,
            value.shellescape
          ].join("=")
        end
      end
    end

    if cmd.empty?
      true
    else
      out, err, rc = Invoker.instance.crm_configure_load_update(cmd.join(" "))
      rc == 0
    end
  end
end
