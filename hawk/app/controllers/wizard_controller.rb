#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., All Rights Reserved.
#
# Author: Tim Serong <tserong@novell.com>
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

require "rexml/document" unless defined? REXML::Document

# TODO(must): file paths are used semi-raw, verify this can't cause trouble

#
# We have an arbitrarily long set of steps, the first one and last two
# of which are fixed, specifically:
#
#   - choose workflow
#   - workflow params       (optional)
#   - workflow template 1   (optional)
#   - workflow template 2   (optional)
#   - ...                   (optional)
#   - summarize/confirm
#   - commit
#
# There must be at least one of workflow params or one template
# referenced by the workflow (i.e. at least one screen of settings for
# the user to enter).
#

class WizardController < ApplicationController
  before_filter :login_required, :load_wizard_config

  layout "main"

  def initialize
    super
    @title = _("Cluster Setup Wizard")
    @confdir = File.join(RAILS_ROOT, "config", "wizard")
    @steps = ["workflow", "confirm", "commit"]
    @step = "workflow"
    @errors = []
    @all_params = {}      # everything that's set, by step
    @step_params = {}     # possible params for current step
  end

  def run
    @step = params[:step] if params[:step]

    @all_params = params[:all_params] || {}
    @all_params[@step] = params[:step_params] if params[:step_params]

    if params[:workflow]
      if params[:back]
        prev_step
      else
        # Next is implicit (it's disabled on click, so we don't see the field here)
        next_step
      end
    end

    sp = @step.split("_", 2)
    case sp[0]
    when "workflow"
      start
    when "params"
      # get params & help from workflow
      set_step_params(@workflow_xml.root)
    when "template"
      # sp[1] has the template id, basically same thing as for params,
      # but get the param list from the template
      set_step_params(@templates_xml[sp[1]].root,
        @workflow_xml.root.elements["templates/template[@name='#{sp[1]}']"])
    when "confirm"
      # print out everything that's been set up
      # how?  what did we specify?  do we do it in chunks (what you just entered)
      # or as crm config we're about to apply?  (less friendly)
      
      @crm_script = ""
      # Here we need to know:
      # - Which templates were actually used (if some are optional)
      #   (note that this each loop here is wrong, we need to base it on
      #   extant params, really, but this'll work for a POC).
      #   Should really just load all templates each time through...
      # - Generate crm script for each one
      @workflow_xml.root.elements.each('templates/template') do |e|
        @crm_script += get_crm_script(@templates_xml[e.attributes['name']].root.elements["crm_script"], "template_#{e.attributes['name']}", false)
      end

      # - Generate crm script for workflow
      @crm_script += get_crm_script(@workflow_xml.root.elements["crm_script"], "params", false)
      
    when "commit"
    
      crm_script = ""
      @workflow_xml.root.elements.each('templates/template') do |e|
        crm_script += get_crm_script(@templates_xml[e.attributes['name']].root.elements["crm_script"], "template_#{e.attributes['name']}")
      end

      # - Generate crm script for workflow
      crm_script += get_crm_script(@workflow_xml.root.elements["crm_script"], "params")
      
      crm_script += "\ncommit\n"
      
      result = Invoker.instance.crm_configure crm_script
      if result == true
        @msg = _("Done, shiny")
      else
        @msg = _("It didn't work: %{msg}") % { :msg => result }
        # Errors come back like:
        #   WARNING: asyncmon: operation not recognized
        #   ERROR: 6: filesystem: id is already in use
        #   ERROR: 11: virtual-ip: id is already in use
        #   ERROR: 14: apache: id is already in use
        #   ERROR: 18: web-server: id is already in use
        #   INFO: 20: apparently there is nothing to commit
        #   INFO: 20: try changing something first        
      end
    else
      # This can't happen
    end
  end

  private

  def start
    @descs = {}
    @workflows.each do |w|
      f = File.join(@confdir, "workflows", "#{w}.xml")
      xml = REXML::Document.new(File.new(f))
      # TODO(should): select by language instead of forcing en
      sd = xml.root.elements['shortdesc[@lang="en"]']
      next unless sd
      d = { :shortdesc => sd.text.strip }
      if xml.root.elements['longdesc[@lang="en"]']
        d[:longdesc] = xml.root.elements['longdesc[@lang="en"]'].text.strip 
      end
      @descs[w] = d
    end
    render "start"
  end

  # TODO(should): next/prev are a bit light on error checking of step names...
  def next_step
    # Trying to go to the next step, must validate current step first
    sp = @step.split("_", 2)
    case sp[0]
    when "params"
      validate_params(@workflow_xml.root, "params")
    when "template"
      validate_params(@templates_xml[sp[1]].root, @step)
    end

    return if @errors.any?

    i = @steps.index(@step)
    @step = @steps[i + 1] if i < @steps.length - 1
  end

  def prev_step
    i = @steps.index(@step)
    @step = @steps[i - 1] if i > 0
  end

  def set_step_params(root, override_with = nil)
    root.elements.each('parameters/parameter') do |e|
      override = override_with ?
        override_with.elements["override[@name='#{e.attributes['name']}']"] : nil
      @step_params[e.attributes['name']] = {
        # TODO(should): select by language instead of forcing en
        :shortdesc => e.elements['shortdesc[@lang="en"]'].text.strip || '',
        :longdesc  => e.elements['longdesc[@lang="en"]'].text.strip || '',
        :type     => e.elements['content'].attributes['type'],
        :default  => e.elements['content'].attributes['default'],
        :default  => override ?
          override.attributes['value'] : e.elements['content'].attributes['default'],
        :required => e.attributes['required'].to_i == 1 ? true : false
      }
    end
  end

  def validate_params(root, step)
    root.elements.each('parameters/parameter') do |e|
      if e.attributes['required'].to_i == 1
        if !@all_params[step].has_key?(e.attributes['name']) ||
           @all_params[step][e.attributes['name']].strip.empty?
          @errors << _('Required parameter "%{param}" not specified') % { :param => e.attributes['name'] }
        end
      end
    end
  end

  def load_wizard_config
    ["templates", "workflows"].each do |d|
      files = Dir.glob(File.join(@confdir, d, "*.xml"))
      if files.empty?
        @errors << _("Wizard templates and/or workflows are missing")
        break
      end
      instance_variable_set("@#{d}".to_sym, files.map{|f| File.basename(f, ".xml")})
    end

    if params[:workflow]
      if !@workflows.include?(params[:workflow])
        @errors << _('Workflow "%s" not found') % params[:workflow]
      else
        f = File.join(@confdir, "workflows", "#{params[:workflow]}.xml")
        @workflow_xml = REXML::Document.new(File.new(f))
        if @workflow_xml.root
          @steps.insert(@steps.rindex("confirm"), "params") if @workflow_xml.root.elements['parameters']
          @workflow_xml.root.elements.each('templates/template') do |e|
            @steps.insert(@steps.rindex("confirm"), "template_#{e.attributes['name']}")
            tf = File.join(@confdir, "templates", "#{e.attributes['name']}.xml")
            @templates_xml ||= {}
            @templates_xml[e.attributes['name']] = REXML::Document.new(File.new(tf))
            @errors << _('Error parsing template "%s"') % e.attributes['name'] unless @templates_xml[e.attributes['name']].root
          end
        else
          @errors << _('Error parsing workflow "%s"') % params[:workflow]
        end
      end
    end

    render "broken" if @errors.any?
  end

  def get_crm_script(element, context, runnable=true)
    s = generate_crm_script(element, context)
    # strip blank lines, inject continuation \ if desired
    s.split("\n").select{|line| !line.strip.empty?}.join(runnable ? " \\\n" : "\n") + "\n"
  end

  def generate_crm_script(element, context)
    s = ""
    element.children.each do |c|
      case c.node_type
      when :text
        s += c.value
      when :element
        case c.name
        when "insert"
          # Takes param="param_name", optionally with from_template="template_name"
          set = c.attributes["from_template"] ? "template_#{c.attributes['from_template']}" : context
          s += @all_params[set][c.attributes["param"]] || "ERROR"
          # TODO(must): Handle error properly
        when "if"
          # Takes set="param_name" or template_used="template_name"
          # TODO(must): This check is (probably) wrong for determining template used
          if (c.attributes["set"] && @all_params[context][c.attributes["set"]]) ||
             (c.attributes["template_used"] && @all_params["template_#{c.attributes['template_used']}"])
            s += generate_crm_script(c, context)
          end
        end
      end
    end
    s
  end

end
