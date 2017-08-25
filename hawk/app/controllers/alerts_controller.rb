# Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

class AlertsController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: current_cib.alerts.to_json
      end
    end
  end

  def new
    @title = _("Create Alert")
    @alert = Alert.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:alert].permit!
    @title = _("Create Alert")

    alertdata = params[:alert].permit!
    alertdata["recipients"] = alertdata["recipients"].values unless alertdata["recipients"].nil?
    @alert = Alert.new alertdata

    respond_to do |format|
      if @alert.save
        post_process_for! @alert

        format.html do
          flash[:success] = _("Alert created successfully")
          redirect_to edit_cib_alert_url(cib_id: @cib.id, id: @alert.id)
        end
        format.json do
          render json: @alert, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @alert.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Alert")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:alert].permit!
    @title = _("Edit Alert")

    if params[:revert]
      return redirect_to edit_cib_alert_url(cib_id: @cib.id, id: @alert.id)
    end

    respond_to do |format|
      alertdata = params[:alert].permit!
      alertdata["recipients"] = alertdata["recipients"].values
      if @alert.update_attributes(alertdata)
        post_process_for! @alert

        format.html do
          flash[:success] = _("Alert updated successfully")
          redirect_to edit_cib_alert_url(cib_id: @cib.id, id: @alert.id)
        end
        format.json do
          render json: @alert, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @alert.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @alert.id)
      if rc == 0
        format.html do
          flash[:success] = _("Alert deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to edit_cib_config_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Alert deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@alert.id, err]
          redirect_to edit_cib_alert_url(cib_id: @cib.id, id: @alert.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@alert.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @alert.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Alerts")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @alert = Alert.find params[:id]

    unless @alert
      respond_to do |format|
        format.html do
          flash[:alert] = _("The alert does not exist")
          redirect_to edit_cib_config_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
  end

  def default_base_layout
    "withrightbar"
  end
end
