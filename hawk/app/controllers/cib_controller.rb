#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
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
    
    # This blob is remarkably like the CIB, but staus is consolidated into the
    # main sections (nodes, resources) rather than being kept separate.
    render :json => {
      :meta => {
        :epoch    => cib.epoch,
        :dc       => cib.dc
      },
      :errors     => cib.errors,
      :crm_config => cib.crm_config,
      :tickets    => cib.tickets,
      :nodes      => cib.nodes,
      :resources  => cib.resources,
      # eventaully want constraints, op_defaults, rsc_defaults, ...
      # Note: passing localized labels here, because we can't wrap an arbitrary number of plurals in _gettext.js
      :nodes_label => n_('1 node configured', '%{num} nodes configured', cib.nodes.length) % { :num => cib.nodes.length },
      :resources_label => n_('1 resource configured', '%{num} resources configured', cib.resource_count) % { :num => cib.resource_count }
    }
  end

  def update
    head :forbidden
  end

  def destroy
    head :forbidden
  end
end
