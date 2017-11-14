# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class PrimitivesController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show, :copy]

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
    @primitive.parent = params[:parent] unless params[:parent].nil?

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:primitive].permit!
    @title = _("Create Primitive")

    @primitive = Primitive.new params[:primitive].permit!

    fail CreateFailure, Util.strip_error_message(@primitive) unless @primitive.save
    post_process_for! @primitive

    unless @primitive.parent.blank?
      parent = Group.find @primitive.parent
      if parent
        parent.children.push @primitive.id
        fail CreateFailure, Util.strip_error_message(parent) unless parent.save
      end
    end

    respond_to do |format|
      format.html do
        flash[:success] = _("Primitive created successfully")
        if @primitive.parent.blank?
          redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
        else
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @primitive.parent)
        end
      end
      format.json do
        render json: @primitive, status: :created
      end
    end
  rescue CreateFailure => e
    respond_to do |format|
      format.html do
        flash[:danger] = e.to_s
        render action: "new"
      end
      format.json do
        render json: @primitive.errors, status: :unprocessable_entity
      end
    end
  end

  def edit
    @title = _("Edit Primitive")

    respond_to do |format|
      format.html
    end
  end

  def copy
    @title = _("Create Primitive")
    other = @primitive
    @primitive = Primitive.new
    @primitive.unique_id! other.id
    @primitive.clazz = other.clazz
    @primitive.provider = other.provider
    @primitive.type = other.type
    @primitive.template = other.template
    @primitive.params = other.params
    @primitive.meta = other.meta
    @primitive.ops = other.ops
    @primitive.utilization = other.utilization

    render 'primitives/new'
  end

  def update
    normalize_params! params[:primitive].permit!
    @title = _("Edit Primitive")

    if params[:revert]
      return redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
    end

    respond_to do |format|
      if @primitive.update_attributes(params[:primitive].permit!)
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
      _out, err, rc = Invoker.instance.crm("configure", "delete", @primitive.id)
      if rc == 0
        format.html do
          flash[:success] = _("Primitive deleted successfully")
          flash[:warning] = err unless err.blank?
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
          flash[:alert] = _("Error deleting %s: %s") % [@primitive.id, err]
          redirect_to edit_cib_primitive_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@primitive.id, err] }, status: :unprocessable_entity
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
    "withrightbar"
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
