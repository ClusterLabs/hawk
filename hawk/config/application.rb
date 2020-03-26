# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require File.expand_path("../boot", __FILE__)
require File.expand_path('../../app/lib/hawk/secure_cookies', __FILE__)


module Hawk
  class Application < Rails::Application
    config.generators do |g|
      g.assets false
      g.helper false
      #g.orm :active_record
      g.template_engine :erb

      # g.test_framework :rspec, fixture: true
      # g.fallbacks[:rspec] = :test_unit
    end

    config.autoload_paths += [
      config.root.join("lib"),
      config.root.join("app", "collections")
    ]

    config.encoding = "utf-8"
    config.time_zone = "UTC"

    #config.app_middleware.delete(
    #  "ActiveRecord::QueryCache"
    #)

    config.active_support.escape_html_entities_in_json = true

    config.i18n.enforce_available_locales = false

    # Set the secure flag for all the cookies
    config.middleware.insert_after ActionDispatch::Static, Hawk::SecureCookies

    if Rails.env.development?
      if config.respond_to? :web_console
        config.web_console.whitelisted_ips = ["192.168.0.0/16", "10.0.2.2", "10.13.37.0/24"]
      end
    else
      config.middleware.use Rack::Deflater
    end

    config.x.hawk_is_sles = system("cat /etc/os-release | grep 'ID=.*sles' >/dev/null 2>&1")

    def lookup_daemon_dir
      [
        "/usr/libexec/pacemaker",
        "/usr/lib64/pacemaker",
        "/usr/lib/pacemaker",
        "/usr/lib64/heartbeat",
        "/usr/lib/heartbeat"
      ].each do |dir|
        [
          "crmd",
          "pacemaker-controld",
        ].each do |cmd|
          return dir if File.executable? "#{dir}/#{cmd}"
        end
      end
      "/usr/libexec/pacemaker"
    end

    config.x.crm_daemon_dir = lookup_daemon_dir
  end
end
