# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.configure do
  # Because we have the /monitor controller, we need
  # to change some settings here. Unfortunately, it
  # interferes with the auto-reloading of changed code.
  config.preload_frameworks = true
  config.allow_concurrency = true
  config.quiet_assets = false
  config.cache_classes = true
  config.eager_load = true


  config.consider_all_requests_local = true
  config.serve_static_files = true
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

  config.cache_store = :null_store

  config.assets.debug = true
  config.assets.raise_runtime_errors = true
  config.assets.js_compressor = nil
  config.assets.css_compressor = nil
  config.assets.compile = true
  config.assets.digest = true
  config.assets.manifest = Rails.root.join("public", "assets", "manifest.json")

  config.i18n.fallbacks = false

  config.log_level = :debug
  config.log_tags = []

  config.logger = ActiveSupport::TaggedLogging.new(
    Logger.new(Rails.root.join("log", "development.log"))
  )

  config.web_console.whitelisted_ips = '10.0.2.2'
end
