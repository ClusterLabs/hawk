#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2013 SUSE LLC., All Rights Reserved.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include FastGettext::Translation

  #protect_from_forgery
  helper :all

  layout :detect_current_layout

  around_filter :inject_current_user
  before_filter :set_users_locale
  before_filter :set_current_title
  before_filter :set_cors_headers
  before_filter :init_shadow_cib

  helper_method :is_god?
  helper_method :logged_in?
  helper_method :current_user
  helper_method :relative_url_root

  # Force back to status page if e.g.: cluster offline when trying to access
  # resources, etc.
  # rescue_from CibObject::CibObjectError, RuntimeError do |e|
  #   if params[:controller] == "main" || params[:controller] == "cib"
  #     render :status => 400, :json => {
  #       :error => e
  #     }
  #   else
  #     redirect_to status_path
  #   end
  # end

  def initialize
    super

    require 'socket'
    @host = Socket.gethostname  # should be short hostname

    # Need a default homedir for bare crm invocations that's
    # writeable by hacluster
    ENV['HOME'] = File.join(Rails.root, 'tmp', 'home')
  end



  def current_user
    @_current_user ||= session[:username]
  end

  #
  # Technique based on one presented by a very unhappy sounding person at:
  #
  #   http://m.onkey.org/how-to-access-session-cookies-params-request-in-model
  #
  # If you ever read this, o unhappy one, I'm not injecting controller data
  # into my models, but I *do* need the current user when models invoke
  # external commands to update the cluster configuration (this is required
  # for ACLs to work properly in this application, which has nothing to do
  # with Rails at all), and I'm damn well not passing the current user to
  # every model, when the models themselves actually don't need to care who
  # is using them.
  #

  protected

  def detect_current_layout
    if request.xhr?
      false
    else
      "application"
    end
  end

  def inject_current_user
    current_controller = self

    Invoker.send(
      :define_method,
      "current_user",
      proc { current_controller.current_user }
    )

    yield

    Invoker.send(
      :remove_method,
      "current_user"
    )
  end

  def set_users_locale
    I18n.locale = FastGettext.set_locale(
      params[:locale] || cookies[:locale] || request.env["HTTP_ACCEPT_LANGUAGE"] || "en-US"
    )
  end

  def set_current_title
    @title ||= ""
  end

  def set_cors_headers
    if request.headers["Origin"]
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
      response.headers["Access-Control-Allow-Credentials"] = "true"
    end
  end

  def init_shadow_cib
    ENV.delete("CIB_shadow")

    if params[:cib_id] && params[:cib_id] != "live"
      # TODO(must): figure out if this is safe
      ENV['CIB_shadow'] = params[:cib_id]
    elsif params[:controller] == "cib" && params[:id] && params[:id] != "live"
      ENV['CIB_shadow'] = params[:id]
    end

    # init a shadow cib and return the URL to redirect to with shadow CIB id embedded
    if params[:sim] && params[:sim] == "init"
      shadow_id = "hawk-#{current_user}"
      result = Invoker.instance.run("crm_shadow", "-b", "-f", "-c", shadow_id)

      if result == true
        if params[:controller] == "explorer"
          render :json => {
            :uri => url_for(:controller => 'main', :action => 'status', :cib_id => shadow_id, :sim => nil)
          }
        else
          render :json => {
            :uri => url_for(:cib_id => shadow_id, :sim => nil)
          }
        end
      else
        render :json => {
          :error  => _('Unable to create shadow CIB'),
          :stderr => result[1]
        }, :status => 500
      end
    end
  end



  def logged_in?
    !!current_user
  end

  def authorized?
    logged_in?
  end

  def login_required
    authorized? || access_denied
  end

  # Tests:
  # 1) JSON
  #    - load status page
  #    - hit logout link, but open in new tab
  #    - try some mgmt op in status page (start/stop resource)
  #    - this should give "permission denied" dialog
  # 2) HTML
  #    - as above, but after logout, reload the status page
  #    - you should be redirected back to the login page
  def access_denied
    respond_to do |format|
      format.any do
        # Have to use format.any not format.html due to stupid IE accept
        # header brokenness.  Further, format.any must preceed format.json,
        # or no dice...
        store_location
        redirect_to login_url
      end
      format.json do
        # This will kill e.g. JSON requests when not logged in.
        head :forbidden
      end
    end
  end

  # Only use this if you need the cluster to be online, and *don't* have a Cib
  # (or other thing handy) that'll throw an appropriate exception.  Note that
  # this check is conservative, i.e. it'll redirect if and only if it's
  # impossible to connect to the CIB, but not in case of any other possible
  # error that crm_mon might return.
  def cluster_online
    %x[/usr/sbin/crm_mon -s >/dev/null 2>&1]
    redirect_to status_path if $?.exitstatus == Errno::ENOTCONN::Errno
  end

  def store_location
    session[:return_to] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Check if the user is sufficiently privileged to access sensitive
  # information (syslog via hb_report/crm_report, "crm history")
  def is_god?
    return current_user == "hacluster" || current_user == "root"
  end
end
