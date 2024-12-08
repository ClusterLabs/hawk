# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.config.tap do |config|
  config.assets.version = "1.0"

  config.assets.precompile = %w( manifest.js )
  config.assets.precompile << [
    "gettext.css", "gettext.js",
    "application.css","application.js",
    "authentication.css", "authentication.js",
    "dashboard.css", "dashboard.js",
    "ie.css", "ie.js",
    "vendor.css", "vendor.js"
  ]
end
