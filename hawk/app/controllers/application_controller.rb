# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ApplicationController < ActionController::Base
  include FastGettext::Translation

  protect_from_forgery with: :exception
  helper :all

  layout :detect_current_layout

  around_filter :inject_current_user
  around_filter :inject_current_cib
  before_filter :set_users_locale
  before_filter :set_current_home
  before_filter :set_current_title
  before_filter :set_shadow_cib
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  helper_method :is_god?
  helper_method :logged_in?
  helper_method :production_cib
  helper_method :current_cib
  helper_method :current_user

  rescue_from Cib::CibError do |e|
    respond_to do |format|
      format.json do
        head e.head
      end
      format.html do
        redirect_to e.redirect!(root_url), alert: e.message
      end
    end
  end

  rescue_from Cib::NotAuthenticated do |e|
    respond_to do |format|
      format.json do
        head :forbidden
      end
      format.html do
        store_location
        redirect_to login_url
      end
    end
  end

  protected

  def production_cib
    "live"
  end

  def current_cib
    if current_user
      @current_cib ||= begin
        # backwards compatibility
        if params[:cib_id] == "mini"
          params[:mini] = "true"
          params[:cib_id] = production_cib
        end
        Cib.new(params[:cib_id] || production_cib, current_user, params[:debug] == "file")
      end
    end
  end

  def redirect_back(default)
    redirect_to(session[:return_to] || default)
  end

  def store_location
    session[:return_to] = request.url
  end

  def detect_current_layout
    if request.xhr?
      false
    else
      default_base_layout
    end
  end

  def default_base_layout
    "application"
  end

  def inject_current_cib
    current_controller = self
    Thread.current[:current_cib] = proc { current_controller.send(:current_cib) }
    yield
  end

  def inject_current_user
    current_controller = self
    Thread.current[:current_user] = proc { current_controller.send(:current_user) }
    yield
  end

  def set_users_locale
    available = [params[:locale], cookies[:locale], default_locale].compact.first
    I18n.locale = FastGettext.set_locale(available)
    cookies[:locale] = FastGettext.locale unless cookies[:locale] == FastGettext.locale
  end

  def set_current_home
    ENV["HOME"] = Rails.root.join("tmp", "home").to_s
  end

  def set_current_title
    @title ||= ""
  end

  def cors_set_access_control_headers
    if request.headers['Origin']
      response.headers['Access-Control-Allow-Origin'] = request.headers["Origin"]
      response.headers['Access-Control-Allow-Credentials'] = 'true'
      response.headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, X-CSRF-Token, Token'
      response.headers['Access-Control-Max-Age'] = "1728000"
    end
  end

  def cors_preflight_check
    if request.method == 'OPTIONS' && request.headers['Origin']
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
      response.headers['Access-Control-Allow-Credentials'] = 'true'
      response.headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, X-CSRF-Token, Token'
      response.headers['Access-Control-Max-Age'] = '1728000'

      render json: {}, status: 200
    end
  end

  def set_shadow_cib
    if !current_cib || current_cib.live?
      ENV.delete("CIB_shadow")
      return
    end

    init_cib = params[:init_cib].to_s.downcase == "true"
    result = nil
    ENV['CIB_shadow'] = current_cib.id
    if init_cib || !File.exist?("/var/lib/pacemaker/cib/shadow.#{current_cib.id}")
      result = Invoker.instance.run("crm_shadow", "-b", "-f", "-c", "#{current_cib.id}")
    end

    if result.nil?
      Rails.logger.debug "Using Shadow CIB for #{current_cib.id}"
      return
    end

    respond_to do |format|
      if result[2] == 0
        format.html do
          Rails.logger.debug "Created Shadow CIB for #{current_cib.id}: #{result.inspect}"
          flash.now[:success] = _("Created a new shadow CIB for %USER%.").sub("%USER%", current_cib.id)
          redirect_to cib_path(cib_id: current_cib.id)
        end
      else
        format.html do
          redirect_to root_path, alert: (_("Unable to create shadow CIB") + ": " + result[1].to_s)
        end
        format.json do
          render json: { error: _("Unable to create shadow CIB"), stderr: result[1] }, status: 500
        end
      end
    end
  end

  def current_user
    @current_user ||= session[:username]
  end

  def is_god?
    current_user == "hacluster" || current_user == "root"
  end

  def logged_in?
    current_user.present?
  end

  def login_required
    not_authenticated unless logged_in?
  end

  def god_required
    permission_denied unless is_god?
  end

  def permission_denied
    raise Cib::PermissionDenied.new
  end

  def not_authenticated
    raise Cib::NotAuthenticated.new
  end

  def not_found
    raise ActionController::RoutingError.new "Record not found"
  end

  def default_locale
    "en-US"
  end
end
