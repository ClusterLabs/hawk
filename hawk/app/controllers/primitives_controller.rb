# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class PrimitivesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Primitive.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Primitive")
    @primitive = Primitive.new
    @primitive.meta["target-role"] = "Stopped" if @cib.id == "live"

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:primitive]
    @title = _("Create Primitive")

    @primitive = Primitive.new params[:primitive]

    respond_to do |format|
      if @primitive.save
        post_process_for! @primitive

        format.html do
          flash[:success] = _("Primitive created successfully")
          redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: @primitive, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @primitive.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Primitive")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:primitive]
    @title = _("Edit Primitive")

    if params[:revert]
      return redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
    end

    respond_to do |format|
      if @primitive.update_attributes(params[:primitive])
        post_process_for! @primitive

        format.html do
          flash[:success] = _("Primitive updated successfully")
          redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: @primitive, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @primitive.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if Invoker.instance.crm("--force", "configure", "delete", @primitive.id)
        format.html do
          flash[:success] = _("Primitive deleted successfully")
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Primitive deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s") % @primitive.id
          redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: { error: _("Error deleting %s") % @primitive.id }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @primitive.to_json
      end
      format.any { not_found  }
    end
  end

  def options
    respond_to do |format|
      format.json do
        render json: Primitive.options.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Primitives")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @primitive = Primitive.find params[:id]

    unless @primitive
      respond_to do |format|
        format.html do
          flash[:alert] = _("The primitive does not exist")
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
    if ["new", "create", "edit", "update"].include? params[:action]
      "withrightbar"
    else
      super
    end
  end

  def provider_params
    params.permit(
      :clazz
    )
  end

  def type_params
    params.permit(
      :clazz,
      :provider
    )
  end
end
