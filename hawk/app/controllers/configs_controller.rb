# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

class ConfigsController < ApplicationController
  before_action :login_required
  skip_before_action :verify_authenticity_token

  def show
    respond_to do |format|
      format.html do
        cmd = "show"
        cmd = "show xml" if params[:xml] == "true"
        out, err, rc = Invoker.instance.no_log do |invoker|
          invoker.crm_configure cmd
        end
        if rc != 0
          format.any { head :internal_server_error }
        else
          @cibtext = out
          @xml = params[:xml] == "true"
          render
        end
      end
      format.json do
        render json: current_cib.status()
      end
      format.xml do
        out, err, rc = Invoker.instance.no_log do |invoker|
          invoker.crm_configure "show xml"
        end
        if rc != 0
          format.any { head :internal_server_error }
        else
          render xml: out
        end
      end
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :not_found
      end
      format.any { head :not_found }
    end
  rescue SecurityError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :forbidden
      end
      format.any { head :forbidden }
    end
  rescue RuntimeError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :internal_server_error
      end
      format.any { head :internal_server_error }
    end
  end

  def meta
    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  protected

  def detect_modal_layout
    if request.xhr? && params[:action] == :meta
      "modal"
    else
      detect_current_layout
    end
  end
end
