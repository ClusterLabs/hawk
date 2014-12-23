#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
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

class SessionsController < ApplicationController
  def new
    @session = Session.new

    respond_to do |format|
      format.html do
        redirect_back_or_default root_url if authorized?
      end
      format.json do
        render json: {}, status: 200
      end
    end
  end

  def create
    @session = Session.new params[:session]

    respond_to do |format|
      if @session.valid?
        reset_session
        session[:username] = @session.username

        format.html do
          redirect_back_or_default root_url
        end
        format.json do
          render json: {}, status: 200
        end
      else
        format.html do
          flash.now[:alert] = @session.errors.first.last
          render action: "new"
        end
        format.json do
          render json: { errors: @session.errors.values }, status: 403
        end
      end
    end
  end

  def destroy
    if params[:reason] == "forbidden"
      message = if session[:username]
        _("Permission denied for user %{user}") % { user: session[:username] }
      else
        _("You have been logged out")
      end
    end

    session[:username] = nil
    reset_session

    respond_to do |format|
      format.html do
        redirect_to login_url, alert: message
      end
      format.json do
        render json: {}, status: 200
      end
    end
  end

  protected

  def detect_current_layout
    if request.xhr?
      false
    else
      "login"
    end
  end

  def set_current_title
    @title = _("Log In")
  end
end
