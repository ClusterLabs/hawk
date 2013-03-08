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
  layout 'main'

  def initialize
    super
    @title = _('Log In')
  end

  def show
    redirect_to :action => 'new'
  end

  def new
    respond_to do |format|
      format.any do
        # render login screen if not already logged in
        redirect_back_or_default root_url if authorized?
      end
      format.json do
        # Explicity allow CORS
        # TODO(should): Consolidate with CibController and ApplicationController
        if request.headers["Origin"]
          response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
          response.headers["Access-Control-Allow-Credentials"] = "true"
        end
        # This is fake, to allow the dashboard to figure out whether it
        # can talk to this node at all (very quick response)
        render :status => 200, :json => nil
      end
    end
  end

  # called from login screen
  HAWK_CHKPWD = '/usr/sbin/hawk_chkpwd'
  def create
    ok = false
    msg = ""
    if params[:username].blank?
      msg = _('Username not specified')
    elsif params[:username].include?("'") || params[:username].include?("$")
      # No ' or $ characters, because this is going to the shell
      msg = _('Invalid username')
    elsif params[:password].blank?
      msg = _('Password not specified')
    else
      if File.exists?(HAWK_CHKPWD) && File.executable?(HAWK_CHKPWD)
        IO.popen("#{HAWK_CHKPWD} passwd '#{params[:username]}'", 'w+') do |pipe|
          pipe.write params[:password]
          pipe.close_write
        end
        if $?.exitstatus == 0
          # The user can log in, and they're in our required group
          reset_session
          session[:username] = params[:username]
          ok = true
        else
          # No dice...
          msg = _('Invalid username or password')
        end
      else
        msg = _('%s is not installed') % HAWK_CHKPWD
      end
    end

    respond_to do |format|
      format.any do
        if ok
          redirect_back_or_default root_url
        else
          flash[:warning] = msg
          redirect_to :action => 'new', :username => params[:username]
        end
      end
      format.json do
        # Explicity allow CORS
        # TODO(should): Consolidate with CibController and ApplicationController
        if request.headers["Origin"]
          response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
          response.headers["Access-Control-Allow-Credentials"] = "true"
        end
        if ok
          render :status => 200, :json => nil
        else
          render :status => 403, :json => { :errors => [ msg ] }
        end
      end
    end
  end

  def destroy
    previous_user = session[:username]
    session[:username] = nil
    reset_session
    if params[:reason] == 'forbidden'
      if previous_user
        flash[:warning] =
          _('Permission denied for user %{user}') % {:user => previous_user}
      else
        flash[:warning] =
          _('You have been logged out')
      end
    end
    redirect_to :action => 'new'
  end

end
