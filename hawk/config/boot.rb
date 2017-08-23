# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

STDOUT.sync = true
STDERR.sync = true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require "socket"
require "open3"
require "rexml/document"

if File.exist? ENV["BUNDLE_GEMFILE"]
  require "bundler/setup"
  require "active_record/railtie"
  require "active_model/railtie"
  require "action_controller/railtie"
  require "action_view/railtie"
  require "sprockets/railtie"
  require "rails/test_unit/railtie"

  Bundler.require(*Rails.groups)
else
  gem "rails", version: "~> 5"
  require "active_record/railtie"
  require "active_model/railtie"
  require "action_controller/railtie"
  require "action_view/railtie"
  require "sprockets/railtie"
  require "rails/test_unit/railtie"

  gem "puma", version: "~> 3"
  require "puma"

  gem "sass-rails", version: "~> 5.0"
  require "sass-rails"

  gem "virtus", version: "~> 1.0"
  require "virtus"

  gem "js-routes", version: ">= 1.3.3"
  require "js-routes"

  gem "tilt", version: "~> 2.0"
  require "tilt"

  gem "fast_gettext", version: "~> 1.4"
  require "fast_gettext"

  gem "gettext_i18n_rails", version: "~> 1.8"
  require "gettext_i18n_rails"

  gem "gettext_i18n_rails_js", version: "~> 1.3"
  require "gettext_i18n_rails_js"

  gem "sprockets", version: ">= 3.7"
  require "sprockets"

  gem "kramdown", version: ">= 1.14"
  require "kramdown"
end
