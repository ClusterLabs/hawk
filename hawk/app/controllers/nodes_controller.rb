#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

class NodesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:online, :standby, :maintenance, :ready, :fence, :show, :events]

  before_filter :god_required, only: [:events]

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
      format.js
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
    if request.xhr? && params[:action] == :show
      "modal"
    else
      detect_current_layout
    end
  end
end
