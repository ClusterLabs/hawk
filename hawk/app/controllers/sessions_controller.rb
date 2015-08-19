# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

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
