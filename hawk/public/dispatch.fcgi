#!/usr/bin/ruby

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../vendor")

require 'rubygems'
require 'fcgi'

#require_relative '../config/environment'
require File.dirname(__FILE__) + "/../config/environment"

class Rack::PathInfoRewriter
  def initialize(app)
    @app = app
  end

  def call(env)
    env.delete('SCRIPT_NAME')
    parts = env['REQUEST_URI'].split('?')
    env['PATH_INFO'] = parts[0]
    env['QUERY_STRING'] = parts[1].to_s
    @app.call(env)
  end
end

Rack::Handler::FastCGI.run  Rack::PathInfoRewriter.new(Hawk::Application)

