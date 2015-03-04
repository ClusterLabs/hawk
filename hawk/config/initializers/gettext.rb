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

Rails.application.config.gettext_i18n_rails.tap do |config|
  config.msgmerge = ['--sort-output', '--no-wrap']
  config.xgettext = ['--sort-output', '--no-wrap']
end

FastGettext.tap do |config|
  config.add_text_domain 'hawk', path: Rails.root.join('locale').to_s

  config.default_text_domain = 'hawk'
  config.default_available_locales = ['en-US'.to_sym]

  Dir[Rails.root.join('locale', '*', 'LC_MESSAGES', '*.mo').to_s].each do |l|
    next unless l.match(/\/([^\/]+)\/LC_MESSAGES\/.*\.mo$/)
    next if config.default_available_locales.include? $1

    config.default_available_locales.push $1
  end
end

I18n::Backend::Simple.include(
  I18n::Backend::Fallbacks
)

I18n.fallbacks['en_US'.to_sym] = ['en-US'.to_sym, :en]
I18n.fallbacks['en_GB'.to_sym] = ['en-GB'.to_sym, :en]
I18n.fallbacks['pt_BR'.to_sym] = ['pt-BR'.to_sym, :pt]
I18n.fallbacks['zh_CN'.to_sym] = ['zh-CN'.to_sym]
I18n.fallbacks['zh_TW'.to_sym] = ['zh-TW'.to_sym]
