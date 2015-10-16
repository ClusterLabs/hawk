# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Ticket < Constraint
  attribute :id, String
  attribute :ticket, String
  attribute :loss_policy, String
  attribute :resources, Array[Hash]
  attribute :granted, Boolean
  attribute :standby, Boolean

  validates :id,
    presence: { message: _("Constraint ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Constraint ID") }

  validates :ticket,
    presence: { message: _("Ticket ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Ticket ID") }

  validate do |record|
    if record.resources.empty?
      errors.add :base, _("Constraint must consist of at least one separate resources")
    end
  end

  def granted
    current = current_cib.tickets[ticket] || {}

    if current.has_key? :granted
      current[:granted]
    else
      false
    end
  end

  def standby
    current = current_cib.tickets[ticket] || {}

    if current.has_key? :standby
      current[:standby]
    else
      false
    end
  end

  def resources
    @resources ||= []
  end

  def resources=(value)
    @resources = value
  end

  def grant!(site)
    raise Constraint::CommandError.new _("Simulator active: Use the ticket controls in the simulator") if current_cib.sim?
    out, err, rc = Invoker.instance.run "booth", "client", "grant", "-t", ticket, "-s", site.to_s
    raise Constraint::CommandError.new err unless rc == 0
    rc == 0
  end

  def revoke!(site)
    raise Constraint::CommandError.new _("Simulator active: Use the ticket controls in the simulator") if current_cib.sim?
    out, err, rc = Invoker.instance.run "booth", "client", "revoke", "-t", ticket
    raise Constraint::CommandError.new err unless rc == 0
    rc == 0
  end

  class << self
    def all
      super.select do |record|
        record.is_a? self
      end
    end
  end

  protected

  def shell_syntax
    [].tap do |cmd|
      cmd.push "rsc_ticket #{id} #{ticket}:"

      resources.each do |set|
        cmd.push "(" unless set[:sequential] == "true" && set[:sequential]

        set[:resources].each do |resource|
          if set[:action].empty?
            cmd.push resource
          else
            cmd.push [
              resource,
              set[:action].downcase
            ].join(":")
          end
        end

        cmd.push ")" unless set[:sequential] == "true" && set[:sequential]
      end

      unless loss_policy.blank?
        cmd.push "loss-policy=#{loss_policy}"
      end
    end.join(" ")
  end

  class << self
    def instantiate(xml)
      record = allocate
      record.ticket = xml.attributes["ticket"] || nil
      record.loss_policy = xml.attributes["loss-policy"] || nil

      record.resources = [].tap do |resources|

       Rails.logger.debug xml.inspect

        if xml.attributes["rsc"]
          resources.push(
            sequential: true,
            action: xml.attributes["rsc-role"] || nil,
            resources: [
              xml.attributes["rsc"]
            ]
          )
        else
          xml.elements.each do |resource|
            set = {
              sequential: Util.unstring(resource.attributes["sequential"], true),
              action: resource.attributes["role"] || nil,
              resources: []
            }

            resource.elements.each do |el|
              set[:resources].unshift(
                el.attributes["id"]
              )
            end

            resources.push set
          end
        end
      end

      record
    end

    def cib_type_write
      :rsc_ticket
    end
  end
end
