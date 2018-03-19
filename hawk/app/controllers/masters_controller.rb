# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class MastersController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Master.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Promotable resource")
    @master = Master.new
    @master.meta["target-role"] = "Stopped" if @cib.id == "live"

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:master].permit!
    @title = _("Create Promotable resource")

    @master = Master.new params[:master].permit!

    fail CreateFailure, Util.strip_error_message(@master) unless @master.save
    post_process_for! @master

    respond_to do |format|
      format.html do
        flash[:success] = _("Promotable resource created successfully")
        redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
      end
      format.json do
        render json: @master, status: :created
      end
    end

  rescue CreateFailure => e
    respond_to do |format|
      format.html do
        flash[:danger] = e.to_s
        render action: "new"
      end
      format.json do
        render json: @master.errors, status: :unprocessable_entity
      end
    end
  end

  def edit
    @title = _("Edit Promotable resource")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:master].permit!
    @title = _("Edit Promotable resource")

    if params[:revert]
      return redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
    end

    respond_to do |format|
      if @master.update_attributes(params[:master].permit!)
        post_process_for! @master

        format.html do
          flash[:success] = _("Promotable resource updated successfully")
          redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
        end
        format.json do
          render json: @master, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @master.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @master.id)
      if rc == 0
        format.html do
          flash[:success] = _("Promotable resource deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Promotable resource deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@master.id, err]
          redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@master.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @master.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Promotable resource")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @master = Master.find params[:id]

    unless @master
      respond_to do |format|
        format.html do
          flash[:alert] = _("The Promotable resource (%s) does not exist") % [params[:id]]
          redirect_to types_cib_resources_path(cib_id: @cib.id)
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
