# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.force_ssl = false
  config.autoflush_log = false

  config.action_dispatch.show_exceptions = false
  config.action_dispatch.cookies_serializer = :json
  config.action_dispatch.x_sendfile_header = nil

  config.action_controller.perform_caching = false
  config.action_controller.allow_forgery_protection = false

  # config.action_mailer.raise_delivery_errors = false
  # config.action_mailer.delivery_method = :test

  config.action_view.raise_on_missing_translations = true

  config.active_support.deprecation = :stderr

  # config.active_record.migration_error = :page_load
  # config.active_record.dump_schema_after_migration = false

  config.assets.debug = false
  config.assets.raise_runtime_errors = true
  config.assets.js_compressor = nil
  config.assets.css_compressor = nil
  config.assets.compile = true
  config.assets.digest = false
  config.assets.manifest = Rails.root.join("public", "assets", "manifest.json")

  config.i18n.fallbacks = true

  config.log_level = :debug
  config.log_tags = []

  config.logger = Logger.new(STDOUT)

  config.active_support.test_order = :random
end
