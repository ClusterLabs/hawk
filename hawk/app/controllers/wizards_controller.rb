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

class WizardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  helper_method :workflow_path
  helper_method :workflows

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  protected

  def workflow_path
    @workflow_path ||= Rails.root.join("config", "wizard", "workflows")
  end

  def workflows
    @workflows ||= begin
      {}.tap do |workflows|
        workflow_path.children.sort.each do |file|
          next unless file.extname == ".xml"

          REXML::Document.new(file.read).tap do |xml|
            name = xml.root.elements["shortdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|shortdesc[@lang=\"en\"]"].text.strip
            description = xml.root.elements["longdesc[@lang=\"#{I18n.locale.to_s.gsub("-", "_")}\"]|longdesc[@lang=\"en\"]"].text.strip

            workflows[name.parameterize] = {
              id: name.parameterize,
              name: name,
              description: description
            }
          end
        end
      end
    end
  end

  def default_base_layout
    "withrightbar"
  end











  # # TODO(must): file paths are used semi-raw, verify this can't cause trouble

  # #
  # # We have an arbitrarily long set of steps, the first one and last two
  # # of which are fixed, specifically:
  # #
  # #   - choose workflow
  # #   - workflow params       (optional)
  # #   - workflow template 1   (optional)
  # #   - workflow template 2   (optional)
  # #   - ...                   (optional)
  # #   - summarize/confirm
  # #   - commit
  # #
  # # There must be at least one of workflow params or one template
  # # referenced by the workflow (i.e. at least one screen of settings for
  # # the user to enter).
  # #

  # before_filter :cib_writable, :cluster_online, :load_wizard_config

  # def initialize
  #   super
  #   @title = _("Cluster Setup Wizard")
  #   @confdir = File.join(Rails.root, "config", "wizard")
  #   @scriptdir = File.join(@confdir, "scripts")
  #   @steps = ["workflow", "confirm", "commit"]
  #   @step = "workflow"
  #   @index = 1
  #   @total = 1
  #   @cluster_script = nil
  #   @errors = []
  #   @all_params = {}      # everything that's set, by step
  #   @step_params = {}     # possible params for current step

  #   # required and optional param names broken out into arrays to
  #   # ensure UI order matches order defined in template/workflow
  #   @step_required = []
  #   @step_optional = []
  # end

  # def run
  #   if params[:cancel] || params[:done]
  #     forget_rootpw
  #     redirect_to status_path(:cib_id => (params[:cib_id] || "live"))
  #     return
  #   end

  #   @step = params[:step] if params[:step]

  #   @all_params = params[:all_params] || {}
  #   # Only stash params away in all_params if it doesn't contain the root
  #   # password (else it'd end up being passed back and forth in hidden
  #   # fields on subsequent wizard pages, which seems undesirable).
  #   @all_params[@step] = params[:step_params] if params[:step_params] && !params[:step_params]['rootpw']

  #   if params[:workflow]
  #     if params[:back]
  #       prev_step
  #     else
  #       # Next is implicit (it's disabled on click, so we don't see the field here)
  #       if params[:step_params] && params[:step_params]['rootpw']
  #         if verify_rootpw(params[:step_params]['rootpw'])
  #           remember_rootpw(params[:step_params]['rootpw'])
  #           next_step
  #         else
  #           @errors << _("Invalid password")
  #         end
  #       else
  #         next_step
  #       end
  #     end
  #   end

  #   sp = @step.split("_", 2)
  #   case sp[0]
  #   when "workflow"
  #     forget_rootpw
  #     start
  #   when "rootpw"
  #     @step_shortdesc = _("Root Password")
  #     @step_longdesc = _("The root password is required in order for this wizard template to make configuration changes.")
  #     @step_params['rootpw'] = {
  #       :shortdesc => _("Root Password"),
  #       :longdesc  => _("The root password for this system"),
  #       :type     => 'password',
  #       :default  => '',
  #       :required => true
  #     }
  #     @step_required << 'rootpw'
  #   when "params"
  #     result = run_cluster_script_step("Collect")
  #     unless result == true
  #       @errors << _("Error: #{result}")
  #     end

  #     @step_shortdesc = _("Parameters")
  #     if @workflow_xml.root.elements["parameters/stepdesc[@lang='en']"]
  #       @step_longdesc = @workflow_xml.root.elements["parameters/stepdesc[@lang='en']"].text.strip
  #     end
  #     # get params & help from workflow
  #     set_step_params(@workflow_xml.root)
  #   when "template"
  #     # TODO(should): select by language instead of forcing en
  #     @step_shortdesc = @templates_xml[sp[1]].root.elements['shortdesc[@lang="en"]'].text.strip
  #     if @workflow_xml.root.elements["templates/template[@name='#{sp[1]}']/stepdesc[@lang='en']"]
  #       @step_longdesc = @workflow_xml.root.elements["templates/template[@name='#{sp[1]}']/stepdesc[@lang='en']"].text.strip
  #     end
  #     # sp[1] has the template id, basically same thing as for params,
  #     # but get the param list from the template
  #     set_step_params(@templates_xml[sp[1]].root,
  #       @workflow_xml.root.elements["templates/template[@name='#{sp[1]}']"])

  #     # TODO(must): Make use of this ("skip this step" checkbox, but need to
  #     # remember step was skipped so it remains checked if you go back)
  #     if @workflow_xml.root.elements["templates/template[@name='#{sp[1]}']"].attributes["required"].to_i != 1
  #       @step_is_skippable = true
  #     end

  #   when "confirm"
  #     @step_shortdesc = _("Confirm")

  #     # print out everything that's been set up
  #     # how?  what did we specify?  do we do it in chunks (what you just entered)
  #     # or as crm config we're about to apply?  (less friendly)

  #     # TODO: Use information from Validate
  #     result = run_cluster_script_step("Validate")
  #     unless result == true
  #       @errors << _("Error: #{result}")
  #     end

  #     @crm_script = ""
  #     # Here we need to know:
  #     # - Which templates were actually used (if some are optional)
  #     #   (note that this each loop here is wrong, we need to base it on
  #     #   extant params, really, but this'll work for a POC).
  #     #   Should really just load all templates each time through...
  #     # - Generate crm script for each one
  #     @workflow_xml.root.elements.each('templates/template') do |e|
  #       @crm_script += get_crm_script(@templates_xml[e.attributes['name']].root.elements["crm_script"], "template_#{e.attributes['name']}", false)
  #     end

  #     # - Generate crm script for workflow
  #     @crm_script += get_crm_script(@workflow_xml.root.elements["crm_script"], "params", false)

  #   when "commit"
  #     @step_shortdesc = _("Done")

  #     crm_script = ""
  #     @workflow_xml.root.elements.each('templates/template') do |e|
  #       crm_script += get_crm_script(@templates_xml[e.attributes['name']].root.elements["crm_script"], "template_#{e.attributes['name']}")
  #     end

  #     # - Generate crm script for workflow
  #     crm_script += get_crm_script(@workflow_xml.root.elements["crm_script"], "params")

  #     # TODO: provide crm_script to cluster script
  #     # for verification (by editing the statefile)
  #     result = run_cluster_script_step("Precommit")
  #     unless result == true
  #       @commit_error = result
  #       return
  #     end

  #     result = Invoker.instance.crm_configure crm_script
  #     unless result == true
  #       @commit_error = result
  #       return
  #     end

  #     # TODO: examine result of script execution
  #     result = run_cluster_script_step("Postcommit")
  #     unless result == true
  #       @commit_error = result
  #       return
  #     end

  #     forget_rootpw
  #     render "done"
  #     # Errors come back like:
  #     #   WARNING: asyncmon: operation not recognized
  #     #   ERROR: 6: filesystem: id is already in use
  #     #   ERROR: 11: virtual-ip: id is already in use
  #     #   ERROR: 14: apache: id is already in use
  #     #   ERROR: 18: web-server: id is already in use
  #     #   INFO: 20: apparently there is nothing to commit
  #     #   INFO: 20: try changing something first
  #   else
  #     # This can't happen
  #   end
  # end

  # private

  # # Only use this if you need the cluster to be online, and *don't* have a Cib
  # # (or other thing handy) that'll throw an appropriate exception.  Note that
  # # this check is conservative, i.e. it'll redirect if and only if it's
  # # impossible to connect to the CIB, but not in case of any other possible
  # # error that crm_mon might return.
  # def cluster_online
  #   %x[/usr/sbin/crm_mon -s >/dev/null 2>&1]
  #   redirect_to status_path if $?.exitstatus == Errno::ENOTCONN::Errno
  # end

  # def start
  #   @descs = {}
  #   @workflows.each do |w|
  #     f = File.join(@confdir, "workflows", "#{w}.xml")
  #     xml = REXML::Document.new(File.new(f))
  #     # TODO(should): select by language instead of forcing en
  #     sd = xml.root.elements['shortdesc[@lang="en"]']
  #     next unless sd
  #     d = { :shortdesc => sd.text.strip }
  #     if xml.root.elements['longdesc[@lang="en"]']
  #       d[:longdesc] = xml.root.elements['longdesc[@lang="en"]'].text.strip
  #     end
  #     @descs[w] = d
  #   end
  #   render "start"
  # end

  # # TODO(should): next/prev are a bit light on error checking of step names...
  # def next_step
  #   # Trying to go to the next step, must validate current step first
  #   sp = @step.split("_", 2)
  #   case sp[0]
  #   when "params"
  #     validate_params(@workflow_xml.root, "params")
  #   when "template"
  #     validate_params(@templates_xml[sp[1]].root, @step)
  #   end

  #   return if @errors.any?

  #   i = @steps.index(@step)
  #   @step = @steps[i + 1] if i < @steps.length - 1
  #   @index = @steps.index(@step)
  #   @total = @steps.length - 2
  # end

  # def prev_step
  #   i = @steps.index(@step)
  #   @step = @steps[i - 1] if i > 0
  #   @index = @steps.index(@step)
  #   @total = @steps.length - 2
  # end

  # def set_step_params(root, override_with = nil)
  #   root.elements.each('parameters/parameter') do |e|
  #     override = override_with ?
  #       override_with.elements["override[@name='#{e.attributes['name']}']"] : nil
  #     required = e.attributes['required'].to_i == 1 ? true : false
  #     @step_params[e.attributes['name']] = {
  #       # TODO(should): select by language instead of forcing en
  #       :shortdesc => e.elements['shortdesc[@lang="en"]'].text.strip || '',
  #       :longdesc  => e.elements['longdesc[@lang="en"]'].text.strip || '',
  #       :type     => e.elements['content'].attributes['type'],
  #       :default  => e.elements['content'].attributes['default'],   # TODO(should): Why is this line here?!?
  #       :default  => override ?
  #         override.attributes['value'] : e.elements['content'].attributes['default'],
  #       :required => required
  #     }
  #     if required
  #       @step_required << e.attributes['name']
  #     else
  #       @step_optional << e.attributes['name']
  #     end
  #   end
  # end

  # def validate_params(root, step)
  #   root.elements.each('parameters/parameter') do |e|
  #     if e.attributes['required'].to_i == 1
  #       if !@all_params[step].has_key?(e.attributes['name']) ||
  #          @all_params[step][e.attributes['name']].strip.empty?
  #         @errors << _('Required parameter "%{param}" not specified') % { :param => e.attributes['name'] }
  #       end
  #     end
  #   end
  # end

  # # Rough test for CIB writablity, obeying ACLs if set.  Not exactly lightweight
  # # as it will in fact change the CIB if successful.
  # Rough test for CIB writablity, obeying ACLs if set.  Not exactly lightweight
  # as it will in fact change the CIB if successful.
  # def cib_writable
  #   begin
  #     Invoker.instance.cibadmin("--modify", "--allow-create", "--scope", "crm_config", "--xml-text",
  #       '<cluster_property_set id="hawk-rw-test"/>')
  #     Invoker.instance.cibadmin("--delete", "--xml-text", '<cluster_property_set id="hawk-rw-test"/>')
  #   rescue NotFoundError
  #     # Don't care
  #   rescue SecurityError
  #     # Permission denied
  #     @errors << _("Permission denied - you do not have write access to the CIB.")
  #   rescue RuntimeError
  #     # Not really permission denied, so leaving this alone for the moment
  #   end
  #   render "broken" if @errors.any?
  # end

  # def load_wizard_config
  #   ["templates", "workflows"].each do |d|
  #     files = Dir.glob(File.join(@confdir, d, "*.xml"))
  #     if files.empty?
  #       @errors << _("Wizard templates and/or workflows are missing")
  #       break
  #     end
  #     instance_variable_set("@#{d}".to_sym, files.map{|f| File.basename(f, ".xml")})
  #   end

  #   if params[:workflow]
  #     if !@workflows.include?(params[:workflow])
  #       @errors << _('Workflow "%s" not found') % params[:workflow]
  #     else
  #       f = File.join(@confdir, "workflows", "#{params[:workflow]}.xml")
  #       @workflow_xml = REXML::Document.new(File.new(f))
  #       if @workflow_xml.root
  #         if @workflow_xml.root.attributes.has_key?("cluster_script")
  #           @cluster_script = @workflow_xml.root.attributes["cluster_script"]
  #           @steps.insert(@steps.rindex("confirm"), "rootpw")
  #         end
  #         # TODO(should): select by language instead of forcing en
  #         @workflow_shortdesc = @workflow_xml.root.elements['shortdesc[@lang="en"]'].text.strip
  #         @steps.insert(@steps.rindex("confirm"), "params") if @workflow_xml.root.elements['parameters']
  #         @workflow_xml.root.elements.each('templates/template') do |e|
  #           filename = "#{e.attributes['name']}.xml"
  #           if e.attributes.has_key?("type")
  #             filename = "#{e.attributes['type']}.xml"
  #           end
  #           @steps.insert(@steps.rindex("confirm"), "template_#{e.attributes['name']}")
  #           tf = File.join(@confdir, "templates", filename)
  #           @templates_xml ||= {}
  #           @templates_xml[e.attributes['name']] = REXML::Document.new(File.new(tf))
  #           @errors << _('Error parsing template "%s"') % e.attributes['name'] unless @templates_xml[e.attributes['name']].root
  #         end
  #       else
  #         @errors << _('Error parsing workflow "%s"') % params[:workflow]
  #       end
  #     end
  #   end

  #   render "broken" if @errors.any?
  # end

  # def get_crm_script(element, context, runnable=true)
  #   raw_lines = generate_crm_script(element, context).split("\n").select{|s| !s.strip.empty?}
  #   if runnable
  #     script = ""
  #     current_line = ""
  #     raw_lines.each do |s|
  #       if s.match(/^\s/)
  #         # leading whitespace (continues line)
  #         current_line += s
  #       else
  #         # no leading whitespace, append current line to script and start next line
  #         if !current_line.empty?
  #           script += current_line + "\n"
  #         end
  #         current_line = s
  #       end
  #     end
  #     if !current_line.empty?
  #       script += current_line + "\n"
  #     end
  #     script
  #   else
  #     raw_lines.join("\n") + "\n"
  #   end
  # end

  # def generate_crm_script(element, context)
  #   s = ""
  #   element.children.each do |c|
  #     case c.node_type
  #     when :text
  #       s += c.value
  #     when :element
  #       case c.name
  #       when "insert"
  #         # Takes param="param_name", optionally with from_template="template_name"
  #         set = c.attributes["from_template"] ? "template_#{c.attributes['from_template']}" : context
  #         s += @all_params[set][c.attributes["param"]] || "ERROR"
  #         # TODO(must): Handle error properly
  #       when "if"
  #         # Takes set="param_name" or template_used="template_name"
  #         # TODO(must): This check is (probably) wrong for determining template used
  #         if (c.attributes["set"] && @all_params[context][c.attributes["set"]] && !@all_params[context][c.attributes["set"]].empty?) ||
  #            (c.attributes["template_used"] && @all_params["template_#{c.attributes['template_used']}"])
  #           s += generate_crm_script(c, context)
  #         end
  #       end
  #     end
  #   end
  #   s
  # end

  # def run_cluster_script_step(stepname)
  #   unless @cluster_script
  #     return true
  #   end
  #   script_statefile = "#{Rails.root}/tmp/crm_script.state"
  #   if stepname == "Collect"
  #     # Always recreate state file during collect (this ensures it's owned by
  #     # hacluster, else it'd be owned by root if created by crmsh)
  #     f = File.new(script_statefile, "w")
  #     f.close
  #   end
  #   Invoker.instance.crm_script(recall_rootpw,
  #                               @scriptdir, "run",
  #                               @cluster_script,
  #                               "statefile=#{script_statefile}",
  #                               "step=#{stepname}")
  # end

  # def verify_rootpw(password)
  #   out, err, status = Util.capture3('/usr/bin/su', '--login', 'root', '-c', '/usr/bin/true', :stdin_data => password)
  #   status.exitstatus == 0
  # end

  # def remember_rootpw(password)
  #   # TODO(must): Verify this is really, truly secure
  #   secret = Rails.application.secrets.secret_key_base
  #   unless secret
  #     @errors << _('Cannot store root password securely!')
  #     return
  #   end
  #   crypt = ActiveSupport::MessageEncryptor.new(secret)
  #   session[:rootpw] = crypt.encrypt_and_sign(password)
  # end

  # def recall_rootpw
  #   secret = Rails.application.secrets.secret_key_base
  #   unless secret
  #     @errors << _('Cannot store root password securely!')
  #     return
  #   end
  #   crypt = ActiveSupport::MessageEncryptor.new(secret)
  #   crypt.decrypt_and_verify(session[:rootpw])
  # end

  # def forget_rootpw
  #   session.delete(:rootpw)
  # end





























  protected

  def set_title
    @title = _('Use a wizard')
  end

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end
end
