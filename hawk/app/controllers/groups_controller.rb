# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class GroupsController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Group.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Group")
    @group = Group.new
    @group.meta["target-role"] = "Stopped" if @cib.id == "live"

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:group].permit!
    @title = _("Create Group")

    @group = Group.new params[:group].permit!

    respond_to do |format|
      if @group.save
        post_process_for! @group

        format.html do
          flash[:success] = _("Group created successfully")
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
        end
        format.json do
          render json: @group, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @group.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Group")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:group].permit!
    @title = _("Edit Group")

    if params[:revert]
      return redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
    end

    respond_to do |format|
      if @group.update_attributes(params[:group].permit!)
        post_process_for! @group

        format.html do
          flash[:success] = _("Group updated successfully")
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
        end
        format.json do
          render json: @group, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @group.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @group.id)
      if rc == 0
        format.html do
          flash[:success] = _("Group deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Group deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@group.id, err]
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@group.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @group.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Groups")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @group = Group.find params[:id]

    unless @group
      respond_to do |format|
        format.html do
          flash[:alert] = _("The group does not exist")
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
    role = record.meta["target-role"]
    record.start! if role == "Started"
    record.stop! if role == "Stopped"
    record.promote! if role == "Master"
  end

  def normalize_params!(current)
  end

  def default_base_layout
    "withrightbar"
  end
end
