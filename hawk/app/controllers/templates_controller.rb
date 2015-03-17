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

class TemplatesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.json do
        render json: Template.ordered.to_json
      end
    end
  end

  def new
    @title = _('Create Template')
    @primitive = Template.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:template]
    @title = _('Create Template')

    @primitive = Template.new params[:template]

    respond_to do |format|
      if @primitive.save
        post_process_for! @primitive

        format.html do
          flash[:success] = _('Template created successfully')
          redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: @primitive, status: :created
        end
      else
        format.html do
          render action: 'new'
        end
        format.json do
          render json: @primitive.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _('Edit Template')

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:template]
    @title = _('Edit Template')

    if params[:revert]
      return redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
    end

    respond_to do |format|
      if @primitive.update_attributes(params[:template])
        post_process_for! @primitive

        format.html do
          flash[:success] = _('Template updated successfully')
          redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: @primitive, status: :updated
        end
      else
        format.html do
          render action: 'edit'
        end
        format.json do
          render json: @primitive.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if Invoker.instance.crm('--force', 'configure', 'delete', @primitive.id)
        format.html do
          flash[:success] = _('Template deleted successfully')
          redirect_to cib_dashboard_url(cib_id: @cib.id)
        end
        format.json do
          head :no_content
        end
      else
        format.html do
          flash[:alert] = _('Error deleting %s') % @primitive.id
          redirect_to edit_cib_template_url(cib_id: @cib.id, id: @primitive.id)
        end
        format.json do
          render json: { error: _('Error deleting %s') % @primitive.id }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @primitive.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _('Templates')
  end

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def set_record
    @primitive = Template.find params[:id]

    unless @primitive
      respond_to do |format|
        format.html do
          flash[:alert] = _('The template does not exist')
          redirect_to cib_dashboard_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
  end
end
