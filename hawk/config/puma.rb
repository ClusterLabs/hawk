require 'fileutils'

ROOT = File.expand_path("../../", __FILE__)

def set_config(*args)
  @environment, @threads, @workers, @listen, @port, @key, @cert = args
end

if ENV["HAWK_ENV"] == "development"
  set_config("development", 4, 2, "0.0.0.0", "3000", "/vagrant/hawk/tmp/hawk.key",
             "/etc/hawk/hawk.pem")
  bind "tcp://#{@listen}:#{@port}"
else
  set_config(ENV["HAWK_ENV"] || "production",
             ENV["HAWK_THREADS"] || 16,
             ENV["HAWK_WORKERS"] || 1,
             ENV["HAWK_LISTEN"] || "0.0.0.0",
             ENV["HAWK_PORT"] || "7630",
             ENV["HAWK_KEY"] || "/etc/hawk/hawk.key",
             ENV["HAWK_CERT"] || "/etc/hawk/hawk.pem")
  ssl_bind @listen, @port, cert: @cert, key: @key, verify_mode: 'none'
end

directory ROOT
environment @environment

tag "hawk"

daemonize false
prune_bundler false

threads 0, @threads

workers @workers
worker_timeout 60

pidfile File.join(ROOT, "tmp", "pids", "puma.pid")
state_path File.join(ROOT, "tmp", "pids", "puma.state")

["tmp/pids", "tmp/sessions", "tmp/sockets", "tmp/cache"].each do |name|
  FileUtils.mkdir_p File.join(ROOT, name)
end
