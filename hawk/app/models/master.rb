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

class Master < Record
  attribute :id, String
  attribute :child, String
  attribute :meta, Hash, default: {}

  validates :id,
    presence: { message: _("Master/Slave ID is required") },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _("Invalid Master/Slave ID") }

  validates :child,
    presence: { message: _("No Master/Slave child specified") }

  validate do |record|
    # TODO(must): Ensure children are sanitized
  end

  def mapping
    self.class.mapping
  end

  class << self
    def instantiate(xml)
      record = allocate

      record.child = if xml.elements["primitive|group"]
        xml.elements["primitive|group"].attributes["id"]
      else
        nil
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

      record
    end

    def cib_type
      :master
    end

    def mapping
      # TODO(must): Are other meta attributes for clone valid?
      @mapping ||= begin
        {
          "is-managed" => {
            type: "boolean",
            default: "true"
          },
          "priority" => {
            type: "integer",
            default: "0"
          },
          "target-role" => {
            type: "enum",
            default: "Started",
            values: [
              "Started",
              "Stopped",
              "Master"
            ]
          },
          "clone-max" => {
            type: "integer",
            default: %x[cibadmin -Ql --scope nodes 2>/dev/null].scan("<node ").length
          },
          "clone-node-max" => {
            type: "integer",
            default: "1"
          },
          "notify" => {
            type: "boolean",
            default: "false"
          },
          "globally-unique" => {
            type: "boolean",
            default: "true"
          },
          "ordered" => {
            type: "boolean",
            default: "false"
          },
          "interleave" => {
            type: "boolean",
            default: "false"
          },
          "master-max" => {
            type: "integer",
            default: "1"
          },
          "master-node-max" => {
            type: "integer",
            default: "1"
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
      cmd.push "ms #{id} #{child}"

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
