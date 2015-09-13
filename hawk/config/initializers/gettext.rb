# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.config.gettext_i18n_rails.tap do |config|
  config.msgmerge = ["--sort-output", "--no-wrap"]
  config.xgettext = ["--sort-output", "--no-wrap"]
end

FastGettext.tap do |config|
  config.add_text_domain "hawk", path: Rails.root.join("locale").to_s

  config.default_text_domain = "hawk"
  config.default_locale = "en_US"
  config.default_available_locales = ["en_US"]

  Dir[Rails.root.join("locale", "*", "LC_MESSAGES", "*.mo").to_s].each do |l|
    next unless l.match(/\/([^\/]+)\/LC_MESSAGES\/.*\.mo$/)
    next if config.default_available_locales.include? $1

    config.default_available_locales.push $1
  end
end

I18n::Backend::Simple.include(
  I18n::Backend::Fallbacks
)

I18n.fallbacks["en_US".to_sym] = ["en-US".to_sym, :en]
I18n.fallbacks["en_GB".to_sym] = ["en-GB".to_sym, :en]
I18n.fallbacks["pt_BR".to_sym] = ["pt-BR".to_sym, :pt]
I18n.fallbacks["zh_CN".to_sym] = ["zh-CN".to_sym, :cn]
I18n.fallbacks["zh_TW".to_sym] = ["zh-TW".to_sym, :cn]
