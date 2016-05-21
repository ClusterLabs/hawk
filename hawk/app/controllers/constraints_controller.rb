# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ConstraintsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Constraint.all.to_json
      end
    end
  end

  def status
    respond_to do |format|
      format.json do
        render json: @cib.constraints.to_json
      end
    end
  end

  def types
    respond_to do |format|
      format.html
    end
  end

  def show
    @constraint = Constraint.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  def new
    # redirect depending on type of resource
    constraint = Constraint.find params[:id]
    new_url = "new_cib_#{constraint.object_type}_url".to_sym
    redirect_to send(new_url, cib_id: @cib.id, id: params[:id])
  end

  def edit
    # redirect depending on type of resource
    constraint = Constraint.find params[:id]
    edit_url = "edit_cib_#{constraint.object_type}_url".to_sym
    redirect_to send(edit_url, cib_id: @cib.id, id: params[:id])
  end

  def rename
    from = params[:id]
    to = params[:to]
    @source = params[:source] || "edit"
    @constraint = Constraint.find from

    if to.nil?
      respond_to do |format|
        format.html
      end
    else
      _out, err, rc = Invoker.instance.crm_configure("rename #{from} #{to}")

      respond_to do |format|
        if rc == 0
          msg = _("Successfully renamed %{A} to %{B}") % { A: from, B: to }
          format.html do
            flash[:success] = msg
            redirect_to edit_cib_constraint_url(cib_id: @cib.id, id: to)
          end
          format.json do
            render json: { success: true, message: msg }
          end
        else
          msg = _("Failed to rename %{A} to %{B}: %{E}") % { A: from, B: to, E: err }
          format.html do
            flash[:danger] = msg

            if @source == "constraint"
              redirect_to edit_cib_constraint_url(cib_id: @cib.id, id: from)
            else
              redirect_to edit_cib_config_url(cib_id: @cib.id)
            end
          end
          format.json do
            render json: {
              error: msg
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end

  protected

  def set_title
    @title = _("Constraints")
  end

  def set_cib
    @cib = current_cib
  end

  def default_base_layout
    if ["index", "types"].include? params[:action]
      "withrightbar"
    else
      if params[:action] == "show"
        "modal"
      else
        super
      end
    end
  end
end
