# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.
require 'securerandom'


class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token

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
    @session = Session.new params[:session].permit!

    respond_to do |format|
      if @session.valid?
        reset_session
        session[:username] = @session.username

        # generate random value, store in attrd_updater (1024 Bits)
        value = SecureRandom.hex(128)
        system("/usr/sbin/attrd_updater -R -p -n \"hawk_session_#{@session.username}\" -U \"#{value}\"")
        cookies['hawk_remember_me_id'] = {:value => @session.username, :expires => 7.days.from_now}
        cookies['hawk_remember_me_key'] = {:value => value, :expires => 7.days.from_now}

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
    # delete remember-me keys from cluster nodes by overwriting them with a random number
    random_value = SecureRandom.hex(128)
    system("/usr/sbin/attrd_updater -R -p -n \"hawk_session_#{cookies['hawk_remember_me_id']}\" -U \"#{random_value}\"")
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

  def lang
    locale = if params[:lang].to_s.empty?
      default_locale
    else
      params[:lang]
    end.tr("_", "-")
    cookies[:locale] = locale
    I18n.locale = FastGettext.set_locale(
      locale
    )
    redirect_to login_url
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
