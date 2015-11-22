# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class RolesController < ApplicationController
  before_filter :login_required
  before_filter :feature_support
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]
  before_filter :check_support

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Role.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Role")
    @role = Role.new

    respond_to do |format|
      format.html
    end
  end

  def create
    @title = _("Create Role")
    @role = Role.new params[:role]

    respond_to do |format|
      if @role.save
        post_process_for! @role

        format.html do
          flash[:success] = _("Role created successfully")
          redirect_to cib_roles_url(cib_id: @cib.id)
        end
        format.json do
          render json: @role, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @role.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @title = _("Edit Role")

    if params[:revert]
      return redirect_to edit_cib_role_url(cib_id: @cib.id, id: @role.id)
    end

    respond_to do |format|
      if @role.update_attributes(params[:role])
        post_process_for! @role

        format.html do
          flash[:success] = _("Role updated successfully")
          redirect_to edit_cib_role_url(cib_id: @cib.id, id: @role.id)
        end
        format.json do
          render json: @role, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @role.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @role.id)
      if rc == 0
        format.html do
          flash[:success] = _("Role deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to cib_roles_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Role deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@role.id, err]
          redirect_to cib_roles_url(cib_id: @cib.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@role.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @role.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def feature_support
    unless Util.has_feature? :acl_support
      redirect_to root_url, alert: _("ACL is not supported by the cluster")
    end
  end

  def set_title
    @title = _("Roles")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @role = Role.find params[:id]

    unless @role
      respond_to do |format|
        format.html do
          flash[:alert] = _("The role does not exist")
          redirect_to cib_roles_url(cib_id: @cib.id)
        end
      end
    end
  end

  def check_support
    flash.now[:warning] = view_context.link_to(
      _("To enable ACLs, set \"enable-acl\" in the Cluster Configuration ('Manage > Configuration')"),
      edit_cib_crm_config_path(cib_id: @cib.id)
    ) unless Util.acl_enabled?

    cibadmin = Util.safe_x(
      "/usr/sbin/cibadmin",
      "-Ql",
      "--xpath",
      "/cib[@validate-with]"
    ).lines.first.to_s

    if m = cibadmin.match(/validate-with=\"pacemaker-([0-9.]+)\"/)
      @supported_schema = m.captures[0].to_f >= 2.0
    else
      @supported_schema = false
    end
  end

  def post_process_for!(record)
  end

  def default_base_layout
    "withrightbar"
  end
end
