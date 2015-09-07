# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class MastersController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Master.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Multi-state resource")
    @master = Master.new
    @master.meta["target-role"] = "Stopped" if @cib.id == "live"

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:master]
    @title = _("Create Multi-state resource")

    @master = Master.new params[:master]

    respond_to do |format|
      if @master.save
        post_process_for! @master

        format.html do
          flash[:success] = _("Multi-state resource created successfully")
          redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
        end
        format.json do
          render json: @master, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @master.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Multi-state resource")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:master]
    @title = _("Edit Multi-state resource")

    if params[:revert]
      return redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
    end

    respond_to do |format|
      if @master.update_attributes(params[:master])
        post_process_for! @master

        format.html do
          flash[:success] = _("Multi-state resource updated successfully")
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
      if Invoker.instance.crm("--force", "configure", "delete", @master.id)
        format.html do
          flash[:success] = _("Multi-state resource deleted successfully")
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Multi-state resource deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s") % @master.id
          redirect_to edit_cib_master_url(cib_id: @cib.id, id: @master.id)
        end
        format.json do
          render json: { error: _("Error deleting %s") % @master.id }, status: :unprocessable_entity
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
    @title = _("Multi-state resource")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @master = Master.find params[:id]

    unless @master
      respond_to do |format|
        format.html do
          flash[:alert] = _("The multi-state resource does not exist")
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
