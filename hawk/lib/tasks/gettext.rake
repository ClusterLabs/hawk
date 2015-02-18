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

Rake::Task['gettext:po_to_json'].clear

namespace :gettext do
  desc "Convert PO files to JS"
  task :po_to_json => :environment do
    require 'po_to_json'
    require 'gettext_i18n_rails_js/js_and_coffee_parser'

    GettextI18nRailsJs::JsAndCoffeeParser.js_gettext_function = js_gettext_function

    po_files = Dir["#{locale_path}/**/*.po"]
    if po_files.empty?
      puts "Could not find any PO files in #{locale_path}. Run 'rake gettext:find' first."
    end

    js_locales = Rails.root.join('app', 'assets', 'javascripts', 'gettext', 'locale')
    FileUtils.makedirs(js_locales)

    config_file = Rails.root.join('config', 'gettext_i18n_rails_js.yml')

    opts = if config_file.exist?
      YAML.load_file(config_file.to_s).symbolize_keys
    else
      {}
    end

    po_files.each do |po_file|
      # Language is used for filenames, while language code is used
      # as the in-app language code. So for instance, simplified chinese will
      # live in app/assets/locale/zh_CN/app.js but inside the file the language
      # will be referred to as locales['zh-CN']
      # This is to adapt to the existing gettext_rails convention.
      language = File.basename(File.dirname(po_file))
      language_code = language.gsub('_', '-')

      destination = js_locales.join(language)
      json_string = PoToJson.new(po_file).generate_for_jed(language_code, opts)

      FileUtils.makedirs(destination)
      File.open(File.join(destination, 'app.js'), 'w') { |file| file.write(json_string) }

      puts "Created app.js in #{destination}"
    end

    puts
    puts "All files created, make sure they are being added to your assets file."
    puts
  end

  def files_to_translate
    puts 'translate these files'
    Dir.glob("{app,lib,config,#{locale_path}}/**/*.{rb,erb,haml,slim,js,coffee,handlebars,mustache}")
  end

  # The parser will use this as the function basename when parsing translations.
  def js_gettext_function
    '__'
  end
end
