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

class DashboardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title

  def show
    @clusters = Cluster.all

    render layout: "dashboard"
  end

  def add
    if request.post?
      Rails.logger.debug "Creating from #{params[:cluster]}"
      @cluster = Cluster.new params[:cluster]
      if @cluster.save
        flash[:success] = _("Cluster added successfully")
        redirect_to action: "show"
      else
        render json: @cluster.errors, status: :unprocessable_entity
      end
    else
      @cluster = Cluster.new
      render layout: "modal"
    end
  end

  def remove
    if request.post?
      name = params[:name]
      if Cluster.remove(name)
        flash[:success] = _("Cluster removed successfully")
        redirect_to action: "show"
      else
        render json: { error: _("Error removing %s") % name }, status: :unprocessable_entity
      end
    end
  end

  protected

  def set_title
    @title = _("Dashboard")
  end

  def json_request?
    request.format.json?
  end

end
