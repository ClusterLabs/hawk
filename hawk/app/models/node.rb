# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'invoker'

class Node < Tableless
  class CommandError < StandardError
  end

  attr_accessor :xml
  attribute :id, String
  attribute :name, String
  attribute :params, Hash
  attribute :utilization, Hash
  attribute :utilization_details, Hash
  attribute :state, String
  attribute :online, Boolean
  attribute :standby, Boolean
  attribute :ready, Boolean
  attribute :remote, Boolean
  attribute :maintenance, Boolean
  attribute :fence, Boolean
  attribute :fence_history, String

  validates :id,
    presence: { message: _('Node ID is required') },
    format: { with: /\A[a-zA-Z0-9_]+\z/, message: _('Invalid Node ID') }

  validates :name,
    presence: { message: _('Name is required') },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _('Invalid name') }

  def online!
    out, err, rc = Invoker.instance.run "crm_attribute", "-N", name, "-n", "standby", "-v", "off", "-l", "forever"
    raise CommandError.new err unless rc == 0
    true
  end

  def online
    !standby
  end

  def standby!
    out, err, rc = Invoker.instance.run "crm_attribute", "-N", name, "-n", "standby", "-v", "on", "-l", "forever"
    raise CommandError.new err unless rc == 0
    true
  end

  def ready!
    out, err, rc = Invoker.instance.run "crm_attribute", "-N", name, "-n", "maintenance", "-v", "off", "-l", "forever"
    raise CommandError.new err unless rc == 0
    true
  end

  def ready
    !maintenance
  end

  def maintenance!
    out, err, rc = Invoker.instance.run "crm_attribute", "-N", name, "-n", "maintenance", "-v", "on", "-l", "forever"
    raise CommandError.new err unless rc == 0
    true
  end

  def fence!
    out, err, rc = Invoker.instance.run "crm_attribute", "-t", "status", "-U", name, "-n", "terminate", "-v", "true"
    raise CommandError.new err unless rc == 0
    true
  end

  def to_param
    name
  end

  def help_text
    {
      id: {
        type: "string",
        shortdesc: _("Node ID"),
        longdesc: _("Unique identifier for the node."),
        default: ""
      },
      name: {
        type: "string",
        shortdesc: _("Node Name"),
        longdesc: _("Name used to refer to the node in the cluster."),
        default: ""
      }
    }
  end

  def mapping
    {}.tap do |m|
      m["standby"] = {
        # TODO: Should be boolean, but pacemaker's crappy (yes|true|1) booleans don't map well to the attrlist boolean type :/
        type: "string",
        default: "off",
        longdesc: _("Puts the node into standby mode. The specified node is no longer able to host resources. Any resources currently active on the node will be moved to another node.")
      }
      params.map do |key, _|
        m[key] = {
          type: "string",
          default: "",
          longdesc: ""
        } unless m.key? key
      end
      utilization.map do |key, _|
        m[key] = {
          type: "integer",
          default: "",
          longdesc: ""
        } unless m.key? key
      end
    end
  end

  protected

  def update
    if current_cib.match("//configuration//node[@id='#{id}']").empty?
      errors.add :base, _('The ID "%{id}" does not exist') % { id: id }
      return false
    end

    merge_nvpairs("instance_attributes", params)

    merge_nvpairs("utilization", utilization)

    # write new xml
    begin
      Invoker.instance.cibadmin_replace xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      Rails.logger.debug e.backtrace
      errors.add :base, "Error: #{e.message}"
      return false
    end
    true
  end

  class << self
    def instantiate(xml, state, can_fence)
      record = allocate
      record.id = xml.attributes['id']
      record.xml = xml
      record.name = xml.attributes['uname'] || xml.attributes['id'] || ''
      record.state = state[:state]
      record.standby = state[:standby]
      record.maintenance = state[:maintenance]
      record.remote = state[:remote]
      record.fence_history = state[:fence_history]
      record.fence = can_fence

      record.params = if xml.elements['instance_attributes']
        vals = xml.elements['instance_attributes'].elements.collect do |e|
          [e.attributes['name'], e.attributes['value']]
        end

        Hash[vals.sort]
      else
        {}
      end

      record.utilization_details = {}
      record.utilization = {}.tap do |util|
        if xml.elements['utilization']
          xml.elements['utilization'].elements.each do |e|
            val = e.attributes['value'].to_i
            util[e.attributes['name']] = val
            record.utilization_details[e.attributes['name']] = {
              total: val.to_i,
              used: 0,
              percentage: 0
            }
          end
        end
      end

      if record.utilization_details.any?
        Util.safe_x('/usr/sbin/crm_simulate', '-LU').split("\n").each do |line|
          m = line.match(/^Remaining:\s+([^\s]+)\s+capacity:\s+(.*)$/)

          next unless m && m[1] == record.name

          m[2].split(' ').each do |u|
            name, value = u.split('=', 2)

            if record.utilization_details.has_key? name
              r = record.utilization_details[name]
              remaining = 0
              remaining = value.to_i unless value.nil?
              r[:used] = r[:total] - remaining
              r[:percentage] = 100 - ((remaining.to_f / r[:total].to_f) * 100.0).to_i
            end
          end
        end
      end

      record
    end

    def cib_type
      :node
    end

    def ordered
      all.sort do |a, b|
        a.name.natcmp(b.name, true)
      end
    end

    # Since pacemaker started using corosync node IDs as the node ID attribute,
    # Record#find will fail when looking for nodes by their human-readable
    # name, so have to override here
    def find(id)
      super(id)
    rescue Cib::RecordNotFound
      # Can't find by id attribute, try by name attribute
      super(name, 'name')
    end
  end

  def merge_nvpairs(list, attrs)
    if attrs.empty?
      # No attributes to set, get rid of the list (if it exists)
      xml.elements[list].remove if xml.elements[list]
    else
      # Get rid of any attributes that are no longer set
      if xml.elements[list]
        xml.elements[list].elements.each do |el|
          el.remove unless attrs.keys.include? el.attributes['name']
        end
      else
        xml.add_element(
          list,
          "id" => "#{element_id(xml)}-#{list}")
      end

      # Write new attributes or update existing ones
      attrs.each do |n, v|
        nvp = xml.elements["#{list}/nvpair[@name=\"#{n}\"]"]

        if nvp
          nvp.attributes["value"] = v
        else
          xml.elements[list].add_element(
            "nvpair",
            "id" => "#{element_id(xml.elements[list])}-#{n}",
            "name" => n,
            "value" => v)
        end
      end
    end
  end

  def element_id(elem)
    return elem.attributes['uname'] if elem.attributes['uname']
    elem.attributes['id']
  end
end
