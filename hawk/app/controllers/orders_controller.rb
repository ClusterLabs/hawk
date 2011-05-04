#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., Tim Serong <tserong@novell.com>
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

class OrdersController < ApplicationController
  before_filter :login_required

  layout 'main'
  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def initialize
    super
    @title = _('Edit Order Constraint')
  end

  def new
    @title = _('Create Order Constraint')
    @ord = Order.new
  end

  def create
    @title = _('Create Order Constraint')
    unless params[:cancel].blank?
      redirect_to cib_constraints_path
      return
    end
    @ord = Order.new params[:order]
    if @ord.save
      flash[:highlight] = _('Constraint created successfully')
      redirect_to :action => 'edit', :id => @ord.id
    else
      render :action => 'new'
    end
  end

  def edit
    @ord = Order.find params[:id]
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end
    unless params[:cancel].blank?
      redirect_to cib_constraints_path    # TODO(must): may not work
      return
    end
    @ord = Order.find params[:id]
    if @ord.update_attributes(params[:order])
      flash[:highlight] = _('Constraint updated successfully')
      redirect_to :action => 'edit', :id => @ord.id
    else
      render :action => 'edit'
    end
  end

end
