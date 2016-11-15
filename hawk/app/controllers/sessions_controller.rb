# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'securerandom'


class SessionsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def new
    @session = Session.new

    respond_to do |format|
      format.html do
        redirect_back root_url if logged_in?
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

        # generate random value, store in attrd_updater
        value = SecureRandom.hex[0,12]
        system("attrd_updater -R -p -n \"hawk_session_#{@session.username}\" -U \"#{value}\"")
        cookies['hawk_remember_me_id'] = {:value => @session.username, :expires => 30.days.from_now}
        cookies['hawk_remember_me_key'] = {:value => value, :expires => 30.days.from_now}

        format.html do
          redirect_back root_url
        end
        format.json do
          render json: {}, status: 200
        end
      else
        format.html do
          flash.now[:alert] = @session.errors.first.last
          render action: 'new'
        end
        format.json do
          render json: { errors: @session.errors.values }, status: 403
        end
      end
    end
  end

  def destroy
    if params[:reason] == 'forbidden'
      message = if session[:username]
        _('Permission denied for user %{user}') % { user: session[:username] }
      else
        _('You have been logged out')
      end
    end

    cookies.delete :hawk_remember_me_id
    cookies.delete :hawk_remember_me_key
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
      'authentication'
    end
  end

  def set_current_title
    @title = _('Log In')
  end
end
