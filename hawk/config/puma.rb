# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'fileutils'

ROOT = File.expand_path("../../", __FILE__)
ENVIRONMENT = ENV["HAWK_ENV"] || "production"

THREADS = ENV["HAWK_THREADS"] || 1
WORKERS = ENV["HAWK_WORKERS"] || 2

LISTEN = ENV["HAWK_LISTEN"] || "0.0.0.0"
PORT = ENV["HAWK_PORT"] || "7630"

KEY = ENV["HAWK_KEY"] || "/etc/hawk/hawk.key"
CERT = ENV["HAWK_CERT"] || "/etc/hawk/hawk.pem"

directory ROOT
environment ENVIRONMENT

tag "hawk"

daemonize false
prune_bundler false

threads 0, THREADS

workers WORKERS
worker_timeout 60

pidfile File.join(ROOT, "tmp", "pids", "puma.pid")
state_path File.join(ROOT, "tmp", "pids", "puma.state")

if ENVIRONMENT == "development"
  bind "tcp://#{LISTEN}:#{PORT}"
else
  ssl_bind LISTEN, PORT, cert: CERT, key: KEY
end

[
  "tmp/pids",
  "tmp/sessions",
  "tmp/sockets",
  "tmp/cache"
].each do |name|
  FileUtils.mkdir_p File.join(ROOT, name)
end
