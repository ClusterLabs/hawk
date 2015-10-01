# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'util'
require 'open3'

class MonitorController < ApplicationController
  include ActionController::Live

  skip_around_filter :inject_current_user
  skip_around_filter :inject_current_cib
  skip_before_filter :set_users_locale
  skip_before_filter :set_current_home
  skip_before_filter :set_current_title
  skip_before_filter :set_shadow_cib
  before_filter :login_required
  skip_before_filter :verify_authenticity_token

  def monitor
    ENV['QUERY_STRING'] = request.query_string.to_s
    ENV['HTTP_ORIGIN'] = request.headers['Origin']

    response.headers['Content-Type'] = 'text/event-stream'
    Open3.popen2("/usr/sbin/hawk_monitor") do |_i, o, _t|
      result = o.read
      _, body = result.split("\n\n", 2)
      response.stream.write(body.to_s + "\n")
    end
  ensure
    response.stream.close
  end

end
