#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., All Rights Reserved.
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

# TODO(must): refactor/consolidate primitive & template.

class TemplatesController < ApplicationController
  before_filter :login_required

  layout 'main'
  # Need cib for both edit and update (but ultimately want to minimize the amount of processing...)
  # TODO(should): consolidate/refactor with scaffolding in crm_config_controller
  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def initialize
    super
    @title = _('Edit Template')
  end

  def new
    @title = _('Create Template')
    @res = Template.new
    # Primitives default to target-role=Stopped; not so templates.
    # @res.meta['target-role'] = 'Stopped' if @cib.id == 'live'
    render 'primitives/new'
  end

  def create
    @title = _('Create Template')
    unless params[:cancel].blank?
      redirect_to status_path
      return
    end
    @res = Template.new params[:template]
    if @res.save
      flash[:highlight] = _('Template created successfully')
      redirect_to :action => 'edit', :id => @res.id
    else
      render 'primitives/new'
    end
  end

  def edit
    @res = Template.find params[:id]
    render 'primitives/edit'
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end
    unless params[:cancel].blank?
      redirect_to status_path
      return
    end
    @res = Template.find params[:id]
    if @res.update_attributes(params[:template])
      flash[:highlight] = _('Template updated successfully')
      redirect_to :action => 'edit', :id => @res.id
    else
      render 'primitives/edit'
    end
  end
end
