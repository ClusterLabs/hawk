require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

if File.exists?(ENV['BUNDLE_GEMFILE'])
  require 'bundler/setup'
else
  # These also need to be in Gemfile (see comment at the top of Gemfile
  # for details)
  require 'rails'
  require 'fast_gettext'
  require 'gettext_i18n_rails'
end
