# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.config.tap do |config|
  config.assets.version = "1.0"

  config.assets.precompile = [
    /locale\/.+\.(css|js)$/,
    /gettext\.(css|js)$/,
    /application\.(css|js)$/,
    /authentication\.(css|js)$/,
    /dashboard.(css|js)$/,
    /ie\.(css|js)$/,
    /vendor\.(css|js)$/,
    /\.(jpg|png|gif|svg|ico|eot|woff|woff2|ttf)$/
  ]

  config.assets.paths << config.root.join(
    "vendor",
    "assets",
    "fonts"
  )

  config.assets.paths << config.root.join(
    "vendor",
    "assets",
    "images"
  )
end
