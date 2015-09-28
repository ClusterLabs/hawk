# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'util'
require 'open3'

class MonitorController < ApplicationController
  include ActionController::Live

  def monitor
    ENV['QUERY_STRING'] = request.query_string.to_s
    ENV['HTTP_ORIGIN'] = request.env['HTTP_ORIGIN']

    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
    response.headers['Access-Control-Allow-Credentials'] = "true" # may not be necessary
    Open3.popen3("/usr/sbin/hawk_monitor") do |i, o|
      result = o.read
      _, body = result.split("\n\n", 2)
      response.stream.write(body.to_s + "\n")
    end
  ensure
    response.stream.close
  end

end
