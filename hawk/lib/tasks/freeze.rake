#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
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

def do_or_die(task)
  begin
    Rake::Task[task].invoke
  rescue Exception => e
    raise "#{task} failed: #{e}"
  end
end

namespace :freeze do
  desc "Freeze Rails (but actually fail if there's an error)"
  task :rails do
    do_or_die 'rails:freeze:gems'
  end

  desc "Freeze Gems (but actually fail if there's an error)"
  task :gems do
    do_or_die 'gems:unpack'
    # This little bit of nastiness forces global score for Locale in
    # locale_Rails/i18n.rb, without which we get the error
    # "NoMethodError: undefined method `clear' for I18n::Locale:Module"
    # when running on FC14.  See rhbz#623697 for details.  It's actually
    # fixed in the (unpacked) gem shipped as rubygem-locale_rails.rpm
    # (/usr/lib/ruby/gems/1.8/gems/locale_rails-2.0.5/lib/locale_rails/i18n.rb),
    # but *not* fixed in the .gem file embedded in the RPM
    # (/usr/lib/ruby/gems/1.8/cache/locale_rails-2.0.5.gem), which is
    # what gems:unpack uses as its source.  Presumably this is beacuse
    # the fix isn't/wasn't upstream yet when locale_rails-2.0.5 was
    # packaged on Fedora.
    sh %q{sed -i -e 's/\([^:]\)\(Locale[\.:]\)/\1::\2/g' \
          vendor/gems/locale_rails-*/lib/locale_rails/i18n.rb}
  end
end

