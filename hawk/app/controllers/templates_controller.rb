# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class TemplatesController < ApplicationController
  before_filter :login_required
  before_filter :feature_support
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html do
        render 'primitives/index'
      end
      format.json do
        render json: Template.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Template")
    @primitive = Template.new

    render 'primitives/new'
  end

  def create
    normalize_params! params[:template]
    @title = _("Create Template")

    @primitive = Template.new params[:template]

    respond_to do |format|
      if @primitive.save
        post_process_for! @primitive

        format.html do
          flash[:success] = _("Template created successfully")
          redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: @primitive, status: :created
        end
      else
        format.html do
          render 'primitives/new'
        end
        format.json do
          render json: @primitive.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Template")

    render 'primitives/edit'
  end

  def update
    normalize_params! params[:template]
    @title = _("Edit Template")

    if params[:revert]
      return redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
    end

    respond_to do |format|
      if @primitive.update_attributes(params[:template])
        post_process_for! @primitive

        format.html do
          flash[:success] = _("Template updated successfully")
          redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: @primitive, status: :updated
        end
      else
        format.html do
          render 'primitives/edit'
        end
        format.json do
          render json: @primitive.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @primitive.id)
      if rc == 0
        format.html do
          flash[:success] = _("Template deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to cib_templates_path(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Template deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@primitive.id, err]
          redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
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

  def partial_attributes(attr)
    [
      {},
      params[:clazz],
      params[:provider],
      params[:type]
    ]
  end

  def feature_support
    unless Util.has_feature? :rsc_template
      redirect_to root_url, alert: _("You have no template feature support")
    end
  end

  def set_title
    @title = _("Templates")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @primitive = Template.find params[:id]

    unless @primitive
      respond_to do |format|
        format.html do
          flash[:alert] = _("The template does not exist")
          redirect_to cib_dashboard_url(cib_id: @cib.id)
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
