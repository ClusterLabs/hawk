# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'util'
require 'open3'

class MonitorController < ApplicationController
  include ActionController::Live

  skip_around_action :inject_current_user
  skip_around_action :inject_current_cib
  skip_before_action :set_users_locale
  skip_before_action :set_current_home
  skip_before_action :set_current_title
  skip_before_action :set_shadow_cib
  before_action :login_required
  skip_before_action :verify_authenticity_token
  skip_after_action :cors_set_access_control_headers

  def monitor
    epoch = request.query_string.to_s.split('&').first || ""
    ENV['QUERY_STRING'] = epoch
    ENV['HTTP_ORIGIN'] = request.headers['Origin']

    response.headers['Content-Type'] = 'text/event-stream'
    if request.headers['Origin']
      response.headers['Access-Control-Allow-Origin'] = request.headers["Origin"]
      response.headers['Access-Control-Allow-Credentials'] = 'true'
      response.headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, X-CSRF-Token, Token'
      response.headers['Access-Control-Max-Age'] = "1728000"
    end
    Open3.popen2("/usr/sbin/hawk_monitor") do |_i, o, _t|
      _i.close
      result = o.read
      _, body = result.split("\n\n", 2)
      body = body.to_s.strip + "\n"
      response.stream.write(body)
    end
  ensure
    response.stream.close
  end
end
