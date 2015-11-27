# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.serve_static_files = true
  config.force_ssl = false
  config.autoflush_log = false

  config.action_dispatch.show_exceptions = false
  config.action_dispatch.cookies_serializer = :json
  config.action_dispatch.x_sendfile_header = nil

  config.action_controller.perform_caching = true
  config.action_controller.allow_forgery_protection = true

  # config.action_mailer.raise_delivery_errors = false
  # config.action_mailer.delivery_method = :smtp

  config.action_view.raise_on_missing_translations = false

  config.active_support.deprecation = :notify

  # config.active_record.migration_error = :page_load
  # config.active_record.dump_schema_after_migration = false

  config.assets.debug = false
  config.assets.raise_runtime_errors = false
  config.assets.js_compressor = nil
  config.assets.css_compressor = nil
  config.assets.compile = true
  config.assets.digest = true
  config.assets.manifest = Rails.root.join("public", "assets", "manifest.json")

  config.i18n.fallbacks = true

  config.log_level = :warn
  config.log_tags = []

  config.logger = ActiveSupport::TaggedLogging.new(
    Logger.new(STDOUT)
  )
end
