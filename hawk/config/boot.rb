#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
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

begin
  require 'rubygems'
rescue
end

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

if File.exists? ENV['BUNDLE_GEMFILE']
  require 'bundler/setup'
  require 'active_model/railtie'
  require 'action_controller/railtie'
  require 'action_view/railtie'
  require 'sprockets/railtie'
  require 'rails/test_unit/railtie'

  Bundler.require(*Rails.groups)
else
  gem 'rails', version: '~> 4.2.0'
  require 'active_model/railtie'
  require 'action_controller/railtie'
  require 'action_view/railtie'
  require 'sprockets/railtie'
  require 'rails/test_unit/railtie'

  gem 'puma', version: '~> 2.11.1'
  require 'puma'

  gem 'fast_gettext', version: '~> 0.9.2'
  require 'fast_gettext'

  gem 'gettext_i18n_rails', version: '~> 1.2.0'
  require 'gettext_i18n_rails'

  gem 'gettext_i18n_rails_js', version: '~> 0.0'
  require 'gettext_i18n_rails_js'

  gem 'sprockets', version: '~> 2.12.3'
  require 'sprockets'

  gem 'tilt', version: '~> 1.4.1'
  require 'tilt'

  gem 'virtus', version: '~> 1.0'
  require 'virtus'

  gem 'sass-rails', version: '~> 3.2'
  require 'sass-rails'

  gem 'haml-rails', version: '~> 0.4'
  require 'haml-rails'
end
