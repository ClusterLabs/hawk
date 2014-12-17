#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2012-2013 SUSE LLC, All Rights Reserved.
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
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#======================================================================

class TicketsController < ApplicationController
  before_filter :login_required

  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id], current_user # RORSCAN_ITL (not mass assignment)
  end

  def initialize
    super
    @title = _('Edit Ticket Constraint')
  end

  def new
    @title = _('Create Ticket Constraint')
    @t = Ticket.new
  end

  def create
    @title = _('Create Ticket Constraint')
    unless params[:cancel].blank?
      redirect_to cib_constraints_path
      return
    end
    @t = Ticket.new params[:ticket]  # RORSCAN_ITL (mass ass. OK)
    if @t.save
      flash[:highlight] = _('Constraint created successfully')
      redirect_to :action => 'edit', :id => @t.id
    else
      render :action => 'new'
    end
  end

  def edit
    @t = Ticket.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end
    unless params[:cancel].blank?
      redirect_to cib_constraints_path
      return
    end
    @t = Ticket.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
    if @t.update_attributes(params[:ticket])  # RORSCAN_ITL (mass ass. OK)
      flash[:highlight] = _('Constraint updated successfully')
      redirect_to :action => 'edit', :id => @t.id
    else
      render :action => 'edit'
    end
  end
end
