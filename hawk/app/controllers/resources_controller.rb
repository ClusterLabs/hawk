#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., All Rights Reserved.
#
# Author: Tim Serong <tserong@novell.com>
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
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#======================================================================

# For generic resource functionality only (details, events).
# Specifics (create, delete etc.) belong in Primitive etc.

class ResourcesController < ApplicationController
  before_filter :login_required

  # Not specifying layout because all we do ATM is show individual resource details
  # layout 'main'
#  before_filter :get_cib
#
#  def get_cib
#    @cib = Cib.new params[:cib_id], current_user
#  end
#
  def initialize
    super
    @title = _('Resources')
  end

#  def show
#    @node = Resource.find params[:id]
#  end

  # Don't strictly need CIB for this...
  def events
    unless is_god?
      # TODO(should): duplicates hb_report, nodes_controller: consolidate
      render :permission_denied
      return
    end
    respond_to do |format|
      format.json do
        render "events.js"
      end
      format.any do
        render "events.html"
      end
    end
  end

  def index
    @primitives = Primitive.all
    @templates  = Template.all
    @groups     = Group.all
    @clones     = Clone.all
    @masters    = Master.all
    render :layout => "main"
  end

end
