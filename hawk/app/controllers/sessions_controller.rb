#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
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

class SessionsController < ApplicationController
  layout 'main'

  def initialize
    @title = _('Log In')
  end

  def show
    redirect_to :action => 'new'
  end

  def new
    # render login screen if not already logged in
    redirect_back_or_default root_url if authorized?
  end

  # called from login screen
  HAWK_CHKPWD = '/usr/sbin/hawk_chkpwd'
  def create
    if params[:username].blank?
      flash[:warning] = _('Username not specified')
      redirect_to :action => 'new'
    elsif params[:username].include?("'") || params[:username].include?("$")
      # No ' or $ characters, because this is going to the shell
      flash[:warning] = _('Invalid username')
      redirect_to :action => 'new'
    elsif params[:password].blank?
      flash[:warning] = _('Password not specified')
      redirect_to :action => 'new', :username => params[:username]
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
          redirect_back_or_default root_url
        else
          # No dice...
          flash[:warning] = _('Invalid username or password')
          redirect_to :action => 'new', :username => params[:username]
        end
      else
        flash[:warning] = _('%s is not installed') % HAWK_CHKPWD
        redirect_to :action => 'new', :username => params[:username]
      end
    end
  end

  def destroy
    previous_user = session[:username]
    session[:username] = nil
    reset_session
    flash[:warning] =
      _('Permission denied for user %{user}') % {:user => previous_user} if params[:reason] == 'forbidden'
    redirect_to :action => 'new'
  end

end
