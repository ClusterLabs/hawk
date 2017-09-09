require 'fileutils'

ROOT = File.expand_path("../../", __FILE__)

@environment = ENV["HAWK_ENV"] || "production"
@bind = ENV["HAWK_BIND"] || "unix:///usr/share/hawk/tmp/hawk.sock"

bind @bind
directory ROOT
environment @environment

tag "hawk"

daemonize false
prune_bundler false

threads 0, 1

workers 1

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

worker_timeout 60

pidfile File.join(ROOT, "tmp", "pids", "puma.pid")
state_path File.join(ROOT, "tmp", "pids", "puma.state")

["tmp/pids", "tmp/sessions", "tmp/sockets", "tmp/cache"].each do |name|
  FileUtils.mkdir_p File.join(ROOT, name)
end
