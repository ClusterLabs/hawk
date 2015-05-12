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

class Wizard < Tableless
  attribute :id, String
  attribute :order, String
  attribute :name, String
  attribute :description, String
  attribute :steps, Array[Step]
  attribute :xml, REXML::Document

  def build_step_from_parameter(xml)

  end

  def build_step_from_template(xml)

  end

  class << self
    def parse(file)
      REXML::Document.new(file.read).tap do |xml|
        name = xml.root.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"].text.strip
        description = xml.root.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"].text.strip

        return Wizard.new(
          id: name.parameterize,
          order: file.basename(".xml").to_s,
          name: name,
          description: description,
          xml: xml
        )
      end
    end

    def find(id)
      if workflows[id]
        workflows[id]
      else
        raise CibObject::RecordNotFound, _("Requested workflow does not exist")
      end
    end

    def all
      workflows.values.sort_by(&:order)
    end

    def workflows
      @workflows ||= begin
        {}.tap do |workflows|
          workflow_path.children.each do |file|
            next unless file.extname == ".xml"

            wizard = parse(file)
            workflows[wizard.id] = wizard
          end
        end
      end
    end

    def workflow_path
      @workflow_path ||= Rails.root.join("config", "wizard", "workflows")
    end

    def template_path
      @template_path ||= Rails.root.join("config", "wizard", "templates")
    end

    def script_path
      @script_path ||= Rails.root.join("config", "wizard", "scripts")
    end
  end
end
