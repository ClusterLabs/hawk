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

class GroupsController < ApplicationController
  before_filter :login_required

  layout 'main'

  before_filter :get_cib

  def get_cib
    # This is overkill - we actually only need the cib for its id,
    # and for getting a list of primitives that can be group
    # children when creating a new group.
    @cib = Cib.new params[:cib_id], current_user # RORSCAN_ITL (not mass assignment)
  end

  def initialize
    super
    @title = _('Edit Group')
  end

  def new
    @title = _('Create Group')
    @res = Group.new
    @res.meta['target-role'] = 'Stopped' if @cib.id == 'live'
  end

  def create
    @title = _('Create Group')
    unless params[:cancel].blank?
      redirect_to cib_resources_path
      return
    end
    @res = Group.new params[:group]  # RORSCAN_ITL (mass ass. OK)
    if @res.save
      flash[:highlight] = _('Group created successfully')
      redirect_to :action => 'edit', :id => @res.id
    else
      render :action => 'new'
    end
  end

  def edit
    @res = Group.find params[:id]
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end
    unless params[:cancel].blank?
      redirect_to cib_resources_path
      return
    end
    @res = Group.find params[:id]
    if @res.update_attributes(params[:group])  # RORSCAN_ITL (mass ass. OK)
      flash[:highlight] = _('Group updated successfully')
      redirect_to :action => 'edit', :id => @res.id
    else
      render :action => 'edit'
    end
  end

end
