# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.configure do
  # Because we have the /monitor controller, we need
  # to change some settings here. Unfortunately, it
  # interferes with the auto-reloading of changed code.
  config.preload_frameworks = true
  config.allow_concurrency = true
  config.cache_classes = true
  config.eager_load = true


  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.force_ssl = false
  config.autoflush_log = true

  config.action_dispatch.show_exceptions = true
  config.action_dispatch.cookies_serializer = :json
  config.action_dispatch.x_sendfile_header = nil

  config.action_controller.perform_caching = false
  config.action_controller.allow_forgery_protection = true

  # config.action_mailer.raise_delivery_errors = true
  # config.action_mailer.delivery_method = :smtp

  config.action_view.raise_on_missing_translations = true

  config.active_support.deprecation = :log

  # config.active_record.migration_error = :page_load
  # config.active_record.dump_schema_after_migration = true

  config.cache_store = :memory_store

  config.assets.debug = true
  config.assets.raise_runtime_errors = true
  config.assets.js_compressor = nil
  config.assets.css_compressor = nil
  config.assets.compile = true
  config.assets.digest = true
  config.assets.manifest = Rails.root.join("public", "assets", "manifest.json")

  config.assets.configure do |env|
    if Rails.env.development? || Rails.env.test?
      env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    end
  end

  config.i18n.fallbacks = false

  config.log_level = :debug
  # Prints Logs to STDOUT when starting the Puma server in development mode with
  # the environment variable LOGGER is set to stdout
  # The default is Rails.root/log/development.log
  config.logger = Logger.new(STDOUT) if ENV["LOGGER"] == "stdout"

end
