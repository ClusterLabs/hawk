# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Node < Tableless
  class CommandError < StandardError
  end

  attr_accessor :xml
  attribute :id, String
  attribute :name, String
  attribute :attrs, Hash
  attribute :utilization, Hash
  attribute :state, String
  attribute :online, Boolean
  attribute :standby, Boolean
  attribute :ready, Boolean
  attribute :maintenance, Boolean
  attribute :fence, Boolean

  validates :id,
    presence: { message: _('Node ID is required') },
    format: { with: /\A[0-9]+\z/, message: _('Invalid Node ID') }

  validates :name,
    presence: { message: _('Name is required') },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _('Invalid name') }

  def online!
    out, err, rc = Invoker.instance.run "crm_attribute", "-N", name, "-n", "standby", "-v", "off", "-l", "forever"
    raise CommandError.new err unless rc == 0
    true
  end

  def online
    state == "online"
  end

  def standby!
    out, err, rc = Invoker.instance.run "crm_attribute", "-N", name, "-n", "standby", "-v", "on", "-l", "forever"
    raise CommandError.new err unless rc == 0
    true
  end

  def standby
    state == "standby"
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

  protected

  class << self
    def instantiate(xml, state, can_fence)
      record = allocate
      record.id = xml.attributes['id']
      record.xml = xml
      record.name = xml.attributes['uname'] || ''
      record.state = state[:state]
      record.maintenance = state[:maintenance]
      record.fence = can_fence

      record.attrs = if xml.elements['instance_attributes']
        vals = xml.elements['instance_attributes'].elements.collect do |e|
          [
            e.attributes['name'],
            e.attributes['value']
          ]
        end

        Hash[vals.sort]
      else
        {}
      end

      record.utilization = if xml.elements['utilization']
        vals = xml.elements['utilization'].elements.collect do |e|
          [
            e.attributes['name'],
            e.attributes['value']
          ]
        end

        Hash[vals.sort]
      else
        {}
      end

      if record.utilization.any?
        Util.safe_x('/usr/sbin/crm_simulate', '-LU').split('\n').each do |line|
          m = line.match(/^Remaining:\s+([^\s]+)\s+capacity:\s+(.*)$/)

          next unless m
          next unless m[1] == record.uname

          m[2].split(' ').each do |u|
            name, value = u.split('=', 2)

            if record.utilization.has_key? name
              record.utilization[name][:remaining] = value.to_i
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
      begin
        super(id)
      rescue CibObject::RecordNotFound
        # Can't find by id attribute, try by uname attribute
        super(name, 'uname')
      end
    end
  end
end
