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

class CibController < ApplicationController
  before_filter :login_required

  def show
    @cib = Cib.new(
      params[:id],
      current_user,
      params[:debug] == 'file'
    )

    result = {
      meta: @cib.meta.to_h,
      errors: @cib.errors,
      booth: @cib.booth
    }.tap do |result|
      if params[:id] == 'mini'
        result[:resources] = {}

        result[:resource_states] = {
          pending: 0,
          started: 0,
          failed: 0,
          master: 0,
          slave: 0,
          stopped: 0
        }

        result[:nodes] = []

        result[:node_states] = {
          pending: 0,
          online: 0,
          standby: 0,
          offline: 0,
          unclean: 0
        }

        result[:tickets] = []

        result[:ticket_states] = {
          granted: 0,
          revoked: 0
        }

        current_resources_for(@cib).each do |key, values|
          result[:resources][key] ||= []

          values[:instances].each do |name, attrs|
            result[:resources][key].push name

            case
            when attrs[:master]
              result[:resource_states][:master] += 1
            when attrs[:slave]
              result[:resource_states][:slave] += 1
            when attrs[:started]
              result[:resource_states][:started] += 1
            when attrs[:failed]
              result[:resource_states][:failed] += 1
            when attrs[:pending]
              result[:resource_states][:pending] += 1
            else
              result[:resource_states][:stopped] += 1
            end
          end
        end

        current_nodes_for(@cib).each do |node|
          result[:nodes].push node[:uname]

          case
          when node[:pending]
            result[:node_states][:pending] += 1
          when node[:online]
            result[:node_states][:online] += 1
          when node[:standby]
            result[:node_states][:standby] += 1
          when node[:offline]
            result[:node_states][:offline] += 1
          else
            result[:node_states][:unclean] += 1
          end
        end

        current_tickets_for(@cib).each do |key, values|
          result[:tickets].push key

          case
          when values[:granted]
            result[:ticket_states][:granted] += 1
          else
            result[:ticket_states][:revoked] += 1
          end
        end
      else
        result[:crm_config] = @cib.crm_config
        result[:rsc_defaults] = @cib.rsc_defaults
        result[:op_defaults] = @cib.op_defaults

        result[:tickets] = @cib.tickets
        result[:nodes] = @cib.nodes
        result[:resources] = @cib.resources
      end
    end

    respond_to do |format|
      format.json do
        render json: result
      end
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :not_found
      end
      format.any { head :not_found  }
    end
  rescue SecurityError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :forbidden
      end
      format.any { head :forbidden  }
    end
  rescue RuntimeError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :internal_server_error
      end
      format.any { head :internal_server_error  }
    end
  end

  protected

  def current_resources_for(cib)
    cib.resources_by_id.select do |key, values|
      values[:instances]
    end
  end

  def current_nodes_for(cib)
    cib.nodes
  end

  def current_tickets_for(cib)
    cib.tickets
  end
end
