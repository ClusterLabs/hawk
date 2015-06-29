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

class Step < Tableless
  attribute :title, String
  attribute :description, String

  attribute :labels, Hash, default: {}
  attribute :helps, Hash, default: {}
  attribute :types, Hash, default: {}
  attribute :requires, Hash, default: {}
  attribute :formats, Hash, default: {}
  attribute :order, Array[String], default: []

  class << self
    def from_parameters_xml(xml, wizard)
      self.new.tap do |record|
        record.title = xml.elements[shortdesc_path].text.strip

        record.description = if xml.elements["parameters"].elements[stepdesc_path]
          xml.elements["parameters"].elements[stepdesc_path].text.strip
        else
          ""
        end

        xml.elements.each("parameters/parameter") do |el|
          record.labels[el.attributes["name"]] = el.elements[shortdesc_path].text.strip
          record.helps[el.attributes["name"]] = el.elements[longdesc_path].text.strip
          record.types[el.attributes["name"]] = el.elements["content"].attributes["type"]
          record.order.push el.attributes["name"]

          type = case el.elements["content"].attributes["type"]
          when "boolean"
            Virtus::Attribute::Boolean
          when "enum"
            Virtus::Attribute::String
          when "string"
            Virtus::Attribute::String
          else
            raise "Content type #{el.elements["content"].attributes["type"]} is not supported"
          end

          default = if el.elements["content"].attributes["default"]
            el.elements["content"].attributes["default"].strip
          else
            nil
          end

          self.attribute el.attributes["name"].to_sym, type, default: default

          if el.attributes["required"]
            record.requires[el.attributes["name"]] = true

            self.validates el.attributes["name"].to_sym,
              presence: true
          else
            record.requires[el.attributes["name"]] = false
          end

          if el.attributes["format"]
            record.formats[el.attributes["name"]] = el.attributes["format"]

            self.validates el.attributes["name"].to_sym,
              format: { with: /#{el.attributes["format"]}/ }
          else
            record.formats[el.attributes["name"]] = nil
          end
        end
      end
    end

    def from_templates_xml(xml, wizard)
      REXML::Document.new(
        wizard.template_file(xml.attributes["name"]).read
      ).tap do |template|


#raise template.root.inspect

#xml.elements["parameters"].elements[stepdesc_path]


        record = from_parameters_xml(template.root, wizard)
        record.description = xml.elements[stepdesc_path].text.strip

        return record
      end
    end

    protected

    def stepdesc_path
      "stepdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|stepdesc[@lang=\"en\"]"
    end

    def shortdesc_path
      "shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"
    end

    def longdesc_path
      "longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"
    end
  end
end
