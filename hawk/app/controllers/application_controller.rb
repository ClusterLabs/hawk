# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  init_gettext "hawk"

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

protected

  def logged_in?
    !!current_user
  end

  def current_user
    @_current_user ||= session[:username]
  end

  # Overridable
  def authorized?
    logged_in?
  end

  def login_required
    authorized? || access_denied
  end

  def access_denied
    respond_to do |format|
      format.html do
        store_location
        redirect_to new_session_path
      end
      format.any do
        # TODO: correct?
        head :forbidden
      end
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Make some methods accessible to the view
  helper_method :logged_in?
  helper_method :current_user

end
