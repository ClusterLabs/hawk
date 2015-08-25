# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class WizardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :cib_writable
  before_filter :cluster_online

  helper_method :workflow_path
  helper_method :workflows

  def index
    @wizards = Wizard.all

    respond_to do |format|
      format.html
    end
  end

  def show
    @wizard = Wizard.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  def update
    @wizard = Wizard.find params[:id]
    pa = build_scriptparams(params)
    Rails.logger.debug "params=#{params}"
    Rails.logger.debug "verify=#{pa}"
    @wizard.verify(pa)
    Rails.logger.debug "actions=#{@wizard.actions}"

    respond_to do |format|
      format.html
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
        next unless basestep.required || params.has_key?("enabled:#{basestep.id}")

        name = path.last
        Rails.logger.debug "k=#{k}, v=#{v}, path=#{path}, name=#{name}"
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
      Invoker.instance.cibadmin(
        "--modify",
        "--allow-create",
        "--scope",
        "crm_config",
        "--xml-text",
        "<cluster_property_set id=\"hawk-rw-test\"/>"
      )

      Invoker.instance.cibadmin(
        "--delete",
        "--xml-text",
        "<cluster_property_set id=\"hawk-rw-test\"/>")
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
