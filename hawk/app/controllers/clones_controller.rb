# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ClonesController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Clone.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Clone")
    @clone = Clone.new
    @clone.meta["target-role"] = "Stopped" if @cib.id == "live"

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:clone].permit!
    @title = _("Create Clone")

    @clone = Clone.new params[:clone].permit!

    respond_to do |format|
      if @clone.save
        post_process_for! @clone

        format.html do
          flash[:success] = _("Clone created successfully")
          redirect_to edit_cib_clone_url(cib_id: @cib.id, id: @clone.id)
        end
        format.json do
          render json: @clone, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @clone.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Clone")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:clone].permit!
    @title = _("Edit Clone")

    if params[:revert]
      return redirect_to edit_cib_clone_url(cib_id: @cib.id, id: @clone.id)
    end

    respond_to do |format|
      if @clone.update_attributes(params[:clone].permit!)
        post_process_for! @clone

        format.html do
          flash[:success] = _("Clone updated successfully")
          redirect_to edit_cib_clone_url(cib_id: @cib.id, id: @clone.id)
        end
        format.json do
          render json: @clone, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @clone.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @clone.id)
      if rc == 0
        format.html do
          flash[:success] = _("Clone deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Clone deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@clone.id, err]
          redirect_to edit_cib_clone_url(cib_id: @cib.id, id: @clone.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@clone.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @clone.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Clones")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @clone = Clone.find params[:id]

    unless @clone
      respond_to do |format|
        format.html do
          flash[:alert] = _("The clone does not exist")
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
