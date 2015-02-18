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

  def index
    # Strictly, this is meant to be a list of CIBs, which would thus
    # logically include any accessible shadow CIBs...
    render :json => [ 'live' ]
  end

  def create
    head :forbidden
  end

  def new
    head :forbidden
  end

  def edit
    head :forbidden
  end

  def show

    # We explicitly allow cross-site read-only access to the CIB via AJAX
    # requests so the Dashboard will work.  Still needs a login cookie of
    # course, so this is OK, but we have to set a couple of response headers
    # else Firefox will refuse to give the data from the request to the
    # client.
    if request.headers["Origin"]
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
      response.headers["Access-Control-Allow-Credentials"] = "true"
    end

    begin
      # Not mass assignment (CWE-642) or improper access control (CWE-285)
      # because Cib::initialize sanitizes params[:id], so RORSCAN_INL
      cib = Cib.new(params[:id], current_user, params[:debug] == 'file')
    rescue ArgumentError => e
      render :status => :not_found, :json => { :errors => [ e.message ] }
      return
    rescue SecurityError => e
      render :status => :forbidden, :json => { :errors => [ e.message ] }
      return
    rescue RuntimeError => e
      render :status => 500, :json => { :errors => [ e.message ] }
      return
    end

    if params[:mini]
      # This blob is remarkably like the CIB, but staus is consolidated into the
      # main sections (nodes, resources) rather than being kept separate.
      mini = {
        :meta => {
          :epoch    => cib.epoch,
          :dc       => cib.dc
        },
        :errors     => cib.errors,

        :node_list  => [],
        :node_states => {
          :pending  => 0,
          :online   => 0,
          :standby  => 0,
          :offline  => 0,
          :unclean  => 0
        },
        :resource_states => {
          :pending  => 0,
          :started  => 0,
          :failed   => 0,
          :master   => 0,
          :slave    => 0,
          :stopped  => 0
        },
        :ticket_states => {
          :granted  => 0,
          :revoked  => 0
        },

        :nodes_label => n_('1 node configured', '%{num} nodes configured', cib.nodes.length) % { :num => cib.nodes.length },
        :resources_label => n_('1 resource configured', '%{num} resources configured', cib.resource_count) % { :num => cib.resource_count },

        :booth => cib.booth,
        :tags       => cib.tags
      }

      cib.nodes.each do |n|
        mini[:node_list] << n[:uname]
        mini[:node_states][n[:state]] += 1
      end

      cib.resources_by_id.each do |ri,r|
        next unless r[:instances]
        r[:instances].each do |ii,i|
          if i[:master]
            mini[:resource_states][:master] += 1
          elsif i[:slave]
            mini[:resource_states][:slave] += 1
          elsif i[:started]
            mini[:resource_states][:started] += 1
          elsif i[:failed]
            mini[:resource_states][:failed] += 1
          elsif i[:pending]
            mini[:resource_states][:pending] += 1
          else
            mini[:resource_states][:stopped] += 1
          end
        end
      end

      cib.tickets.each do |ti,t|
        if t[:granted]
          mini[:ticket_states][:granted] +=1
        else
          mini[:ticket_states][:revoked] +=1
        end
      end

      render :json => mini
    else
      # This blob is remarkably like the CIB, but staus is consolidated into the
      # main sections (nodes, resources) rather than being kept separate.
      render :json => {
        :meta => {
          :epoch    => cib.epoch,
          :dc       => cib.dc
        },
        :errors     => cib.errors,
        :crm_config => cib.crm_config,
        :rsc_defaults => cib.rsc_defaults,
        :op_defaults => cib.op_defaults,
        :tickets    => cib.tickets,
        :nodes      => cib.nodes,
        :resources  => cib.resources,
        :tags       => cib.tags,
        # eventaully want constraints, op_defaults, rsc_defaults, ...
        # Note: passing localized labels here, because we can't wrap an arbitrary number of plurals in _gettext.js
        :nodes_label => n_('1 node configured', '%{num} nodes configured', cib.nodes.length) % { :num => cib.nodes.length },
        :resources_label => n_('1 resource configured', '%{num} resources configured', cib.resource_count) % { :num => cib.resource_count },
  :booth => cib.booth
      }
    end
  end

  def update
    head :forbidden
  end

  def destroy
    head :forbidden
  end
end
