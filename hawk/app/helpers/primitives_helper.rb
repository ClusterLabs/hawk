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

module PrimitivesHelper
  def is_template?
    controller.controller_name == "templates"
  end

  def id_prefix
    is_template? ? "template" : "primitive"
  end

  # The view calls Primitive.types to get a list of types for the current
  # class and provider.  When creating a new primitive for the first time,
  # the resource defaults to r_class=ocf, but r_provider='' (see comment in
  # Primitive model for why).  If we call Primitive.types with an empty
  # provider, it will return all available resource types of *all* classes.
  # We don't want that - we only want the types for whatever the default
  # provider is, as it appears in the provider drop-down list.  So here,
  # if r_provider is empty, but there *are* available providers for r_class,
  # we return the first provider (this is passed to Primitive.types in the
  # view)
  def default_provider
    if !@res.r_provider.empty?
      @res.r_provider
    elsif Primitive.classes_and_providers[:r_providers].has_key?(@res.r_class)
      Primitive.classes_and_providers[:r_providers][@res.r_class][0]
    else
      ''
    end
  end
end
