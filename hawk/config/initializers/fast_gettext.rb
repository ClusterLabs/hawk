# define your text domain
FastGettext.add_text_domain 'hawk', :path => File.join(File.dirname(__FILE__), '..', '..', 'po')

# set the default textdomain
FastGettext.default_text_domain = 'hawk'

# set available locales
# (note: the first one is used as a fallback if you try to set an unavailable locale)
FastGettext.default_available_locales = [
  "en_US",
  "ar",
  "cs",
  "de",
  "es",
  "fr",
  "hu",
  "it",
  "ja",
  "ko",
  "nl",
  "pl",
  "pt_BR",
  "ru",
  "sv",
  "zh_CN",
  "zh_TW"
]
