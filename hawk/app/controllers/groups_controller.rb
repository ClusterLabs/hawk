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

class GroupsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def new
    @title = _('Create Group')
    @group = Group.new
    @group.meta['target-role'] = 'Stopped' if @cib.id == 'live'

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:group]
    @title = _('Create Group')

    @group = Group.new params[:group]

    respond_to do |format|
      if @group.save
        post_process_for! @group

        format.html do
          flash[:success] = _('Group created successfully')
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
        end
        format.json do
          render json: @group, status: :created
        end
      else
        format.html do
          render action: 'new'
        end
        format.json do
          render json: @group.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _('Edit Group')

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:group]
    @title = _('Edit Group')

    if params[:revert]
      return redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
    end

    respond_to do |format|
      if @group.update_attributes(params[:group])
        post_process_for! @group

        format.html do
          flash[:success] = _('Group updated successfully')
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
        end
        format.json do
          render json: @group, status: :updated
        end
      else
        format.html do
          render action: 'edit'
        end
        format.json do
          render json: @group.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if Invoker.instance.crm('--force', 'configure', 'delete', @group.id)
        format.html do
          flash[:success] = _('Group deleted successfully')
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
        format.json do
          head :no_content
        end
      else
        format.html do
          flash[:alert] = _('Error deleting %s') % @group.id
          redirect_to edit_cib_group_url(cib_id: @cib.id, id: @group.id)
        end
        format.json do
          render json: { error: _('Error deleting %s') % @group.id }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @group.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _('Groups')
  end

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def set_record
    @group = Group.find params[:id]

    unless @group
      respond_to do |format|
        format.html do
          flash[:alert] = _('The group does not exist')
          redirect_to types_cib_resources_path(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
  end
end
