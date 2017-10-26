# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Tableless
  class ValidationError < RuntimeError
  end

  extend ActiveModel::Naming

  include Virtus.model

  include ActiveModel::Conversion
  include ActiveModel::Validations
  include FastGettext::Translation

  attr_accessor :new_record

  def initialize(attrs = nil)
    self.attributes = attrs unless attrs.nil?
    self.new_record = true
    super
  end

  def save
    valid? && persist!
  end

  def persisted?
    !new_record
  end

  def new_record?
    new_record
  end

  def update_attributes(attrs = nil)
    unless attrs.nil?
      ["meta", "params"].each do |key|
        attrs[key] = {} if self.respond_to?(key.to_sym) && !attrs.key?(key)
      end
      self.attributes = attrs
    end
    save
  end

  def validate!
    fail(ValidationError, errors) unless valid?
  end

  protected

  def create
  end

  def update
  end

  def persist!
    if new_record?
      create
    else
      update
    end
  end

  class << self
    def current_cib
      Thread.current[:current_cib].call
    end
  end

  def current_cib
    self.class.current_cib
  end

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
      default: "Stopped",
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
      default: 0,
      required: false,
      longdesc: _("How frequently(in seconds) to perform the operation.")
    },
    "timeout" => {
      type: "string",
      default: "20",
      required: true,
      longdesc: _("How long to wait before declaring the action has failed.")
    },
    "requires" => {
      type: "enum",
      default: "fencing",
      values: ["nothing", "quorum", "fencing"],
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
      values: ["Stopped", "Started", "Slave", "Master"],
      longdesc: _("This option only makes sense for recurring operations. It restricts the operation to a specific role. The truly paranoid can even specify role=Stopped which allows the cluster to detect an admin that manually started cluster services.")
    },
    "on-fail" => {
      type: "enum",
      default: "stop",
      values: ["ignore", "block", "stop", "restart", "standby", "fence"],
      longdesc: _("The action to take if this action ever fails.")
    },
    "start-delay" => {
      type: "string",
      default: "0",
      longdesc: _("The delay time(in seconds) before doing the operation")
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
  }.freeze
end
