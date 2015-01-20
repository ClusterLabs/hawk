#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2014 SUSE LLC, All Rights Reserved.
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

class PrimitivesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  before_filter :god_required, only: [:events]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Primitive.ordered.to_json
      end
    end
  end












  def new
    @title = _('Create Resource')
    @res = Primitive.new
    @res.meta['target-role'] = 'Stopped' if @cib.id == 'live'
  end

  def create
    @title = _('Create Resource')
    unless params[:cancel].blank?
      redirect_to cib_resources_path
      return
    end
    @res = Primitive.new params[:primitive]  # RORSCAN_ITL (mass ass. OK)
    if @res.save
      #TODO: broken in Rails 4
      edit_url = url_for(:action => 'edit', :id => @res.id)
      edit_link = "<a href=\"#{edit_url}\">#{@res.id}</a>"
      flash[:highlight] = _('Resource created successfully') + ": " + edit_link
      redirect_to :action => 'new'
    else
      render :action => 'new'
    end
  end

  def edit
    @res = Primitive.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
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
    @res = Primitive.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
    if @res.update_attributes(params[:primitive])  # RORSCAN_ITL (mass ass. OK)
      flash[:highlight] = _('Resource updated successfully')
      redirect_to :action => 'edit', :id => @res.id
    else
      render :action => 'edit'
    end
  end

  # Bit of a hack, used only by simulator to get valid intervals
  # for the monitor op in milliseconds.  Returns an array of
  # possible intervals (zero elements if no monitor op defined,
  # one element in the general case, but should be two for m/s
  # resources, or more if there's depths etc.).
  def monitor_intervals
    intervals = []
    @res = Primitive.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
    @res.ops["monitor"].each do |op|
      intervals << Util.crm_get_msec(op["interval"])
    end if @res.ops.has_key?("monitor")
    render :json => intervals
  end

  def types
    render :json => Primitive.types(params[:r_class], params.has_key?(:r_provider) ? params[:r_provider] : '')
  end

  def metadata
    render :json => Primitive.metadata(params[:r_class], params.has_key?(:r_provider) ? params[:r_provider] : '', params[:r_type])
  end






  def events
    respond_to do |format|
      format.json { render :template => "resources/events", :formats => [:js] }
      format.html { render :template => "resources/events" }
    end
  end













  protected

  def set_title
    @title = _('Primitives')
  end

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end
end
