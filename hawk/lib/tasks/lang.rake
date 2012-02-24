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

desc "Update pot/po files."
task :updatepo do
  require 'gettext_rails/tools'
  GetText.update_pofiles("hawk", Dir.glob("{app,lib}/**/*.{rb,erb,rhtml}"),
      "hawk #{ENV['BUILD_TAG'] ? ENV['BUILD_TAG'] : '0.0.0'}")
end

desc "Create mo-files"
task :makemo do
  # Evil hack to workaround https://github.com/rubygems/rubygems/issues/171
  # (see also hawk/config/environment.rb)
  begin
    Gem.all_load_paths
  rescue NoMethodError
    module Gem
      def self.all_load_paths
        []
      end
    end
  end
  require 'gettext_rails/tools'
  GetText.create_mofiles
end

