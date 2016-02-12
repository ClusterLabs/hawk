# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class CibController < ApplicationController
  before_filter :login_required
  skip_before_filter :verify_authenticity_token

  def show
    respond_to do |format|
      format.json do
        render json: current_cib.status(params[:mini] == "true")
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

  def apply
    if request.post?
      out, err, rc = Invoker.instance.crm_configure("cib commit #{current_cib.id}")
      if rc != 0
        Rails.logger.debug "apply fail: #{err}, #{current_cib.id}"
        flash[:danger] = _("Failed to apply configuration")
        redirect_to cib_state_path(cib_id: current_cib.id)
        return
      end
      Rails.logger.debug "apply OK: #{out}"
      flash[:success] = _("Applied configuration successfully")
      redirect_to cib_state_path(cib_id: :live)
    else
      render
    end
  end

  def options
    respond_to do |format|
      format.json do
        render json: {}, status: 200
      end
    end
  end

  protected

  def detect_modal_layout
    if request.xhr? && (params[:action] == :meta || params[:action] == :apply)
      "modal"
    else
      detect_current_layout
    end
  end
end
