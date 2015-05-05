#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

class Ticket < Constraint
  attribute :id, String
  attribute :ticket, String
  attribute :loss_policy, String
  attribute :resources, Array[Hash]

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

  def resources
    @resources ||= []
  end

  def resources=(value)
    @resources = value
  end

  def grant!(site)
    result = Invoker.instance.run(
      "booth", "client", "grant", "-t", id, "-s", site.to_s
    )

    if result == true
      true
    else
      raise Constraint::CommandError.new result.last
    end
  end

  def revoke!(site)
    result = Invoker.instance.run(
      "booth", "client", "revoke", "-t", id
    )

    if result == true
      true
    else
      raise Constraint::CommandError.new result.last
    end
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

      unless loss_policy.empty?
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
