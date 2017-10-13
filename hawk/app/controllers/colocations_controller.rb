# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ColocationsController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Colocation.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Colocation")
    @colocation = Colocation.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:colocation].permit!
    @title = _("Create Colocation")

    @colocation = Colocation.new params[:colocation].permit!

    fail CreateFailure, Util.strip_error_message(@colocation) unless @colocation.save
    post_process_for! @colocation

    respond_to do |format|
      format.html do
        flash[:success] = _("Constraint created successfully")
        redirect_to edit_cib_colocation_url(cib_id: @cib.id, id: @colocation.id)
      end
      format.json do
        render json: @colocation, status: :created
      end
    end

  rescue CreateFailure => e
    respond_to do |format|
      format.html do
        flash[:danger] = e.to_s
        render action: "new"
      end
      format.json do
        render json: @colocation.errors, status: :unprocessable_entity
      end
    end
  end

  def edit
    @title = _("Edit Colocation")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:colocation].permit!
    @title = _("Edit Colocation")

    if params[:revert]
      return redirect_to edit_cib_colocation_url(cib_id: @cib.id, id: @colocation.id)
    end

    respond_to do |format|
      if @colocation.update_attributes(params[:colocation].permit!)
        post_process_for! @colocation

        format.html do
          flash[:success] = _("Constraint updated successfully")
          redirect_to edit_cib_colocation_url(cib_id: @cib.id, id: @colocation.id)
        end
        format.json do
          render json: @colocation, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @colocation.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @colocation.id)
      if rc == 0
        format.html do
          flash[:success] = _("Colocation deleted successfully")
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Colocation deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@colocation.id, err]
          redirect_to edit_cib_colocation_url(cib_id: @cib.id, id: @colocation.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@colocation.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @colocation.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Colocations")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @colocation = Colocation.find params[:id]

    unless @colocation
      respond_to do |format|
        format.html do
          flash[:alert] = _("The colocation constraint does not exist")
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
    if params[:colocation][:resources].nil?
      params[:colocation][:resources] = []
    else
      params[:colocation][:resources] = params[:colocation][:resources].values
    end
  end

  def default_base_layout
    "withrightbar"
  end
end
