# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require File.expand_path("../boot", __FILE__)

module Hawk
  class Application < Rails::Application
    config.generators do |g|
      g.assets false
      g.helper false
      g.orm :active_record
      g.template_engine :haml

      # g.test_framework :rspec, fixture: true
      # g.fallbacks[:rspec] = :test_unit
    end

    config.autoload_paths += [
      config.root.join("lib"),
      config.root.join("app", "collections")
    ]

    config.encoding = "utf-8"
    config.time_zone = "UTC"

    config.app_middleware.delete(
      "ActiveRecord::ConnectionAdapters::ConnectionManagement"
    )

    config.app_middleware.delete(
      "ActiveRecord::QueryCache"
    )

    config.active_support.escape_html_entities_in_json = true

    config.i18n.enforce_available_locales = false

    if Rails.env.development?
      if config.respond_to? :web_console
        config.web_console.whitelisted_ips = ["192.168.0.0/16", "10.0.2.2", "10.13.37.0/24"]
      end
    else
      config.middleware.use Rack::Deflater
    end

    config.x.hawk_is_sles = system("cat /etc/os-release | grep 'ID=.*sles' >/dev/null 2>&1")

    ::Sass::Script::Number.precision = [10, ::Sass::Script::Number.precision].max
  end
end
