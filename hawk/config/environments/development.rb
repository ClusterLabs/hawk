#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
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
end
