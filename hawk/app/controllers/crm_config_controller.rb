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

class CrmConfigController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update]

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if params[:revert]
      return redirect_to edit_cib_crm_config_url(cib_id: @cib.id)
    end

    respond_to do |format|
      if @crm_config.update_attributes(params[:crm_config])
        post_process_for! @crm_config

        format.html do
          flash[:success] = _('Configuration updated successfully')
          redirect_to edit_cib_crm_config_url(cib_id: @cib.id)
        end
        format.json do
          render json: @crm_config, status: :updated
        end
      else
        format.html do
          render action: 'edit'
        end
        format.json do
          render json: @crm_config.errors, status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def set_title
    @title = _('Cluster Configuration')
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @crm_config = CrmConfig.new
  end

  def post_process_for!(record)
  end

  def default_base_layout
    "withrightbar"
  end
end
