# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class TagsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: current_cib.tags.to_json
      end
    end
  end

  def new
    @title = _("Create Tag")
    @tag = Tag.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:tag]
    @title = _("Create Tag")

    @tag = Tag.new params[:tag]

    respond_to do |format|
      if @tag.save
        post_process_for! @tag

        format.html do
          flash[:success] = _("Tag created successfully")
          redirect_to edit_cib_tag_url(cib_id: @cib.id, id: @tag.id)
        end
        format.json do
          render json: @tag, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @tag.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Tag")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:tag]
    @title = _("Edit Tag")

    if params[:revert]
      return redirect_to edit_cib_tag_url(cib_id: @cib.id, id: @tag.id)
    end

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        post_process_for! @tag

        format.html do
          flash[:success] = _("Tag updated successfully")
          redirect_to edit_cib_tag_url(cib_id: @cib.id, id: @tag.id)
        end
        format.json do
          render json: @tag, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @tag.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @tag.id)
      if rc == 0
        format.html do
          flash[:success] = _("Tag deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to cib_dashboard_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Tag deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@tag.id, err]
          redirect_to edit_cib_tag_url(cib_id: @cib.id, id: @tag.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@tag.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @tag.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Tags")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @tag = Tag.find params[:id]

    unless @tag
      respond_to do |format|
        format.html do
          flash[:alert] = _("The tag does not exist")
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
