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

class LocationsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Location.ordered.to_json
      end
    end
  end

  def new
    @title = _('Create Location Constraint')
    @location = Location.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:location]
    @title = _('Create Location Constraint')

    @location = Location.new params[:location]

    respond_to do |format|
      if @location.save
        post_process_for! @location

        format.html do
          flash[:success] = _('Constraint created successfully')
          redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
        end
        format.json do
          render json: @location, status: :created
        end
      else
        format.html do
          render action: 'new'
        end
        format.json do
          render json: @location.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _('Edit Location Constraint')

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:location]
    @title = _('Edit Location Constraint')

    if params[:revert]
      return redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
    end

    respond_to do |format|
      if @location.update_attributes(params[:location])
        post_process_for! @location

        format.html do
          flash[:success] = _('Constraint updated successfully')
          redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
        end
        format.json do
          render json: @location, status: :updated
        end
      else
        format.html do
          render action: 'edit'
        end
        format.json do
          render json: @location.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if Invoker.instance.crm('--force', 'configure', 'delete', @location.id)
        format.html do
          flash[:success] = _('Location deleted successfully')
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
        format.json do
          head :no_content
        end
      else
        format.html do
          flash[:alert] = _('Error deleting %s') % @location.id
          redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
        end
        format.json do
          render json: { error: _('Error deleting %s') % @location.id }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @location.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _('Location Constraints')
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @location = Location.find params[:id]

    unless @location
      respond_to do |format|
        format.html do
          flash[:alert] = _('The location constraint does not exist')
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
  end

  def default_base_layout
    if ["new", "create", "edit", "update"].include? params[:action]
      "withrightbar"
    else
      super
    end
  end
end
