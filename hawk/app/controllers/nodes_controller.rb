# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class NodesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:online, :standby, :maintenance, :ready, :fence, :show, :events, :edit, :update]

  rescue_from Node::CommandError do |e|
    Rails.logger.error e

    respond_to do |format|
      format.json do
        render json: { error: e.message }
      end
      format.html do
        redirect_to cib_nodes_url(cib_id: @cib.id), alert: e.message
      end
    end
  end

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: @cib.nodes_ordered.to_json
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    return redirect_to edit_cib_node_url(cib_id: @cib.id, id: @node.id) if params[:revert]

    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.html do
          flash[:success] = _("Node updated successfully")
          redirect_to edit_cib_node_url(cib_id: @cib.id, id: @node.id)
        end
        format.json do
          render json: @node, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @node.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def online
    @node.online!

    respond_to do |format|
      format.html do
        flash[:success] = _("Set the node state to online")
        redirect_to cib_nodes_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Set the node state to online")
        }
      end
    end
  end

  def standby
    @node.standby!

    respond_to do |format|
      format.html do
        flash[:success] = _("Set the node state to standby")
        redirect_to cib_nodes_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Set the node state to standby")
        }
      end
    end
  end

  def maintenance
    @node.maintenance!

    respond_to do |format|
      format.html do
        flash[:success] = _("Set the node state to maintenance")
        redirect_to cib_nodes_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Set the node state to maintenance")
        }
      end
    end
  end

  def ready
    @node.ready!

    respond_to do |format|
      format.html do
        flash[:success] = _("Set the node state to ready")
        redirect_to cib_nodes_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Set the node state to ready")
        }
      end
    end
  end

  def fence
    @node.fence!

    respond_to do |format|
      format.html do
        flash[:success] = _("Set the node state to fence")
        redirect_to cib_nodes_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Set the node state to fence")
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @node.to_json
      end
      format.html
    end
  end

  def events
    respond_to do |format|
      format.html
    end
  end

  protected

  def set_title
    @title = _("Nodes")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @node = @cib.find_node params[:id]

    unless @node
      respond_to do |format|
        format.html do
          flash[:alert] = _("The node does not exist")
          redirect_to cib_nodes_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def detect_modal_layout
    if request.xhr? && (params[:action] == :show || params[:action] == :events)
      "modal"
    else
      detect_current_layout
    end
  end

  def default_base_layout
    "withrightbar"
  end
end
