# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class NodesController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:online, :standby, :maintenance, :ready, :fence, :clearstate, :show, :events, :edit, :update]

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
        if params[:remote] == "false"
          render json: @cib.nodes_ordered.select { |n| !n.remote }.to_json
        else
          render json: @cib.nodes_ordered.to_json
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
    return redirect_to edit_cib_node_url(cib_id: @cib.id, id: @node.id) if params[:revert]

    respond_to do |format|
      if @node.update_attributes(params[:node].permit!)
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
    run_node_action @node.online!, _("Set the node state to online"), _("Failed to set the node online: %{err}")
  end

  def standby
    run_node_action @node.standby!, _("Set the node state to standby"), _("Failed to set the node standby: %{err}")
  end

  def maintenance
    run_node_action @node.maintenance!, _("Set the node state to maintenance"), _("Failed to set the node state to maintenance: %{err}")
  end

  def ready
    run_node_action @node.ready!, _("Set the node state to ready"), _("Failed to set the node state to ready: %{err}")
  end

  def fence
    run_node_action @node.fence!, _("Successfully fenced the node"), _("Failed to fence the node: %{err}")
  end

  def clearstate
    run_node_action @node.clearstate!, _("Cleared the node state"), _("Failed to clear the node state: %{err}")
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

  def run_node_action(result, success, error)
    _out, err, rc = result

    respond_to do |format|
      if rc == 0
        format.json do
          render json: {
            success: true,
            message: success
          }
        end
      else
        format.json do
          render json: {
            error: error % { err: err }
          }, status: :unprocessable_entity
        end
      end
    end
  end

end
