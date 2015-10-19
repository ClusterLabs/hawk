# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class WizardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :cib_writable
  before_filter :cluster_online

  def index
    @wizards = Wizard.all

    respond_to do |format|
      format.html
    end
  end

  def show
    @wizard = Wizard.find params[:id]
    session[:wizard_session_poke] = "poke"

    respond_to do |format|
      format.html
    end
  end

  def update
    @wizard = Wizard.find params[:id]
    pa = build_scriptparams(params)
    @wizard.verify(pa)
    session[:wizard_data] = pa
    Rails.cache.write("#{params[:id]}/#{session.id}", pa, expires_in: 6.hours)

    respond_to do |format|
      format.html
    end
  end

  def submit
    pa = Rails.cache.fetch("#{params[:id]}/#{session.id}", expires_in: 6.hours) do
      session[:wizard_data]
    end

    if pa.nil?
      render json: [_("Session has expired")], status: :unprocessable_entity
    else
      @wizard = Wizard.find params[:id]
      @wizard.verify(pa)
      if @wizard.errors.length > 0
        render json: @wizard.errors.to_json, status: :unprocessable_entity
      elsif current_cib.sim? && @wizard.need_rootpw
        render json: [_("Wizard cannot be applied when the simulator is active")], status: :unprocessable_entity
      else
        @wizard.run(pa, params[:rootpw])
        if @wizard.errors.length > 0
          render json: @wizard.errors.to_json, status: :unprocessable_entity
        else
          render json: @wizard.actions
        end
      end
    end
  end

  protected

  def build_stepmap(m, container)
    container.steps.each do |s|
      if !s.name.empty?
        if s.required
          m[s.name] = {}
        end
      end
    end
    m
  end

  def build_scriptparams(params)
    sp = build_stepmap({}, @wizard)
    id = @wizard.id
    params.select {|k,v| k.start_with?("#{id}.") }.each do |k, v|
      next if v.empty?
      path = k.split(".").drop(1)
      if path.length > 1
        basestep_idx = @wizard.steps.find_index { |x| x.name == path[0] }
        next if basestep_idx.nil?

        basestep = @wizard.steps[basestep_idx]
        next unless basestep.required || params.has_key?("enable:#{basestep.id}")

        name = path.last
        sub = sp
        path.take(path.length - 1).each do |p|
          sub[p] = {} unless sub.has_key? p
          sub = sub[p]
        end
        sub[name] = v
      else
        sp[path[0]] = v
      end
    end
    #Rails.logger.debug "scriptparams: #{params} -> #{sp}"
    sp
  end

  def default_base_layout
    "withrightbar"
  end

  protected

  def set_title
    @title = _('Use a wizard')
  end

  def set_cib
    @cib = current_cib
  end

  def cib_writable
    begin
      Invoker.instance.cibadmin("--modify", "--allow-create", "--scope",
        "crm_config", "--xml-text", "<cluster_property_set id=\"hawk-rw-test\"/>")

      Invoker.instance.cibadmin("--delete", "--xml-text", "<cluster_property_set id=\"hawk-rw-test\"/>")
    rescue SecurityError
      respond_to do |format|
        format.html do
          redirect_to(
            cib_state_url(cib_id: @cib.id),
            alert: _("Permission denied - you do not have write access to the CIB.")
          )
        end
        format.json do
          render json: {
            error: _("Permission denied - you do not have write access to the CIB.")
          }, status: :unprocessable_entity
        end
      end
    rescue NotFoundError
    rescue RuntimeError
    end
  end

  def cluster_online
    %x[/usr/sbin/crm_mon -s >/dev/null 2>&1]

    if $?.exitstatus == Errno::ENOTCONN::Errno
      respond_to do |format|
        format.html do
          redirect_to(
            cib_state_url(cib_id: @cib.id),
            alert: _("Cluster seems to be offline")
          )
        end
        format.json do
          render json: {
            error: _("Cluster seems to be offline")
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
