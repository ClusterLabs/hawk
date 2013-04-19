# Based on http://lslezak.blogspot.com.au/2012/01/switching-from-gettext-to-fastgettext.html

# define your text domain
FastGettext.add_text_domain 'hawk', :path => File.join(File.dirname(__FILE__), '..', '..', 'locale')

# set the default textdomain
FastGettext.default_text_domain = 'hawk'

# set available locales
# (note: the first one is used as a fallback if you try to set an unavailable locale)
FastGettext.default_available_locales = [ "en_US" ]

# Now grab all the rest on the fly:
Dir[File.join(File.dirname(__FILE__), '..', '..', 'locale', "/*/LC_MESSAGES/*.mo")].each do |l|
  if l.match(/\/([^\/]+)\/LC_MESSAGES\/.*\.mo$/) && !FastGettext.default_available_locales.include?($1)
    FastGettext.default_available_locales << $1
  end
end

# enable fallback handling
I18n::Backend::Simple.include(I18n::Backend::Fallbacks)

# set some locale fallbacks needed for ActiveRecord translations
# located in rails_i18n gem (e.g. there is en-US.yml translation)
I18n.fallbacks[:"en_US"] = [:"en-US", :en]
I18n.fallbacks[:"en_GB"] = [:"en-GB", :en]
I18n.fallbacks[:"pt_BR"] = [:"pt-BR", :pt]
I18n.fallbacks[:"zh_CN"] = [:"zh-CN"]
I18n.fallbacks[:"zh_TW"] = [:"zh-TW"]

# configure default msgmerge parameters (the default contains "--no-location" option
# which removes code lines from the final POT file)
Rails.application.config.gettext_i18n_rails.msgmerge = ["--sort-output", "--no-wrap"]

