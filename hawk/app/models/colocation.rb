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

class Colocation < Constraint
  attribute :id, String
  attribute :score, String
  attribute :node_attr, String
  attribute :resources, Array[Hash]

  validates :id,
    presence: { message: _("Constraint ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Constraint ID") }

  validates :score,
    presence: { message: _("Score is required") }

  validate do |record|
    record.score.strip!

    unless [
      "mandatory",
      "advisory",
      "inf",
      "-inf",
      "infinity",
      "-infinity"
    ].include? record.score.downcase
      unless record.score.match(/^-?[0-9]+$/)
        errors.add :score, _("Invalid score value")
      end
    end

    if record.resources.length < 2
      errors.add :base, _("Constraint must consist of at least two separate resources")
    end
  end

  def resources
    @resources ||= []
  end

  def resources=(value)
    @resources = value
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
      cmd.push "colocation #{id} #{score}:"

      resources.each do |set|
        cmd.push "(" unless set[:sequential] == "true" && set[:sequential]

        set[:resources].each do |resource|
          if set[:action].empty?
            cmd.push resource
          else
            cmd.push [
              resource,
              set[:action]
            ].join(":")
          end
        end

        cmd.push ")" unless set[:sequential] == "true" && set[:sequential]
      end

      unless node_attr.empty?
        cmd.push "node-attribute=#{node_attr}"
      end
    end.join(" ")
  end

  class << self
    def instantiate(xml)
      record = allocate
      record.score = xml.attributes["score"] || nil

      record.resources = [].tap do |resources|
        if xml.attributes["rsc"]
          resources.push(
            sequential: true,
            action: xml.attributes["rsc-role"] || nil,
            resources: [
              xml.attributes["rsc"]
            ]
          )

          resources.push(
            sequential: true,
            action: xml.attributes["with-rsc-role"] || nil,
            resources: [
              xml.attributes["with-rsc"]
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
      :rsc_colocation
    end
  end
end
