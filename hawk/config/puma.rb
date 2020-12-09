require 'fileutils'

ROOT = File.expand_path("../../", __FILE__)

@environment = ENV["HAWK_ENV"] || "production"
@threads =  ENV["HAWK_THREADS"] || 16
@workers =  ENV["HAWK_WORKERS"] || 1
@listen  =  ENV["HAWK_LISTEN"] || "0.0.0.0"
@port =     ENV["HAWK_PORT"] || "7630"
@key  =      ENV["HAWK_KEY"] || "/etc/hawk/hawk.key"
@cert =      ENV["HAWK_CERT"] || "/etc/hawk/hawk.pem"
@no_tlsv1 =  ENV["HAWK_NO_TLSV1"] || false
@no_tlsv1_1 =  ENV["HAWK_NO_TLSV1_1"] || false

ssl_bind @listen, @port, cert: @cert, key: @key, verify_mode: 'none',  no_tlsv1: @no_tlsv1,  no_tlsv1_1: @no_tlsv1_1

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
