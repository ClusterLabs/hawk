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
  attribute :definition, String
  attribute :steps, StepCollection[Step]

  def load!
    REXML::Document.new(definition.read).tap do |xml|
      if xml.root.elements["parameters"]
        steps.push Step.from_parameters_xml(
          xml.root,
          self
        )
      end

      if xml.root.elements["templates"]
        xml.root.elements.each("templates/template") do |template|
          steps.push Step.from_templates_xml(
            template,
            self
          )
        end
      end




#raise steps.inspect

      #steps.push Step.new






    end
  end

  def steps
    @steps ||= StepCollection.new
  end

  def valid?
    super & steps.valid?
  end

  def workflow_file(name)
    self.class.workflow_file(name)
  end

  def template_file(name)
    self.class.template_file(name)
  end

  def script_file(name)
    self.class.script_file(name)
  end

  class << self
    def parse(file)
      REXML::Document.new(
        file.read
      ).tap do |xml|
        name = xml.root.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"].text.strip
        description = xml.root.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"].text.strip
        order = xml.root.attributes["name"]

        return Wizard.new(
          id: file.basename(".xml").to_s,
          order: order,
          name: name,
          description: description,
          definition: file
        )
      end
    end

    def find(id)
      file = workflow_file(id).dup

      if file
        record = parse(file)
        record.load!

        record
      else
        raise CibObject::RecordNotFound, _("Requested workflow does not exist")
      end
    end

    def all
      workflow_files.values.map do |file|
        parse(file)
      end.sort_by(&:order)
    end

    def workflow_path
      @workflow_path ||= Rails.root.join("config", "wizard", "workflows")
    end

    def workflow_files
      @workflow_files ||= begin
        files = workflow_path.children.select do |file|
          if file.extname == ".xml"
            file
          end
        end

        {}.tap do |result|
          files.each do |file|
            result[file.basename(".xml").to_s] = file
          end
        end
      end
    end

    def workflow_file(name)
      workflow_files[name]
    end

    def template_path
      @template_path ||= Rails.root.join("config", "wizard", "templates")
    end

    def template_files
      @template_files ||= begin
        files = template_path.children.select do |file|
          if file.extname == ".xml"
            file
          end
        end

        {}.tap do |result|
          files.each do |file|
            result[file.basename(".xml").to_s] = file
          end
        end
      end
    end

    def template_file(name)
      template_files[name]
    end

    def script_path
      @script_path ||= Rails.root.join("config", "wizard", "scripts")
    end

    def script_files
      @script_files = begin
        files = script_path.children.select do |file|
          if file.directory?
            file
          end
        end

        {}.tap do |result|
          files.each do |file|
            result[file.basename.to_s] = file
          end
        end
      end
    end

    def script_file(name)
      script_files[name]
    end
  end
end
