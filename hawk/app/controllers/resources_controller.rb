#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011-2013 SUSE LLC, All Rights Reserved.
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

  def show
    @res = Resource.find params[:id]

    @op_history = {}

    # Primitives are the only things that can actually have op history and fail counts
    return unless @res.class == Primitive

    # Get fail counts
    xml = REXML::Document.new(Invoker.instance.cibadmin('-Ql', '--xpath', '//status'))
    xml.elements.each("status/node_state/transient_attributes") do |ta|
      n = ta.attributes["id"]
      @op_history[n] = { :fail_count => 0 }
      ta.elements.each("instance_attributes/nvpair") do |nv|
        if nv.attributes["name"].starts_with?("fail-count-")
          id = nv.attributes["name"][11..-1]
          (id, instance) = id.split(':')
          # We throw away instance here (it won't exist anyway on pacemaker >= 1.1.8)
          # (would be more efficient to just assume no instance and ask directly
          # for attribute by name)
          if id == params[:id]
            @op_history[n][:fail_count] = Util.char2score(nv.attributes["value"])
          end
        elsif nv.attributes["name"].starts_with?("last-failure-")
          id = nv.attributes["name"][13..-1]
          (id, instance) = id.split(':')
          # We throw away instance here (it won't exist anyway on pacemaker >= 1.1.8)
          if id == params[:id]
            @op_history[n][:last_failure] = Time.at(nv.attributes["value"].to_i).strftime("%Y-%m-%d %H:%M:%S")
          end
        end
      end
    end if xml.root
  end

  # Don't strictly need CIB for this...
  def events
    unless is_god?
      # TODO(should): duplicates hb_report, nodes_controller: consolidate
      render :permission_denied
      return
    end
    respond_to do |format|
      format.json { render :template => "resources/events", :formats => [:js] }
      format.html { render :template => "resources/events" }
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
