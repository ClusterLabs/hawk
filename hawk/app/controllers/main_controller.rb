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

class MainController < ApplicationController
  before_filter :login_required

  # allow unauthenticated access to translations
  def login_required
    params[:action] == "gettext" ? false : super
  end

  # TODO(must): these both need exception handler for invoker runs
  # TODO(must): only one user at a time can run sims (they stomp on each other)
  def sim_reset
    # TODO(must): can this ever fail?!?
    #Invoker.instance.run("crm_shadow", "-b", "-r", "hawk-#{current_user}")
    # TODO(must): above doesn't clear lrm state - is that a bug? so recreating:
    Invoker.instance.run("crm_shadow", "-b", "-f", "-c", "hawk-#{current_user}")
    head :ok
  end

  def sim_reload_state
    require "tempfile"
    tmpfile = Tempfile.new("cib_state")
    shadow_id = ENV["CIB_shadow"]
    ENV.delete("CIB_shadow")
    tmpfile.write(Invoker.instance.cibadmin('-Ql', '--xpath', '//status'))
    tmpfile.close
    ENV["CIB_shadow"] = shadow_id
    # TODO(must): Handle error here
    result = Invoker.instance.cibadmin('--replace', '--xml-file', tmpfile.path)
    tmpfile.unlink
  end

  def sim_run
    # always reset status before run (so we effectively run from current
    # state of cluster, not state as saved back to shadow cib)
    sim_reload_state

    # TODO(must): sanitize input a bit
    injections = []
    params[:injections].each do |i|
      parts = i.split(/\s+/)
      case parts[0]
      when "node"
        case parts[2]
        when "online"
          injections << "-u" << parts[1]
        when "offline"
          injections << "-d" << parts[1]
        when "unclean"
          injections << "-f" << parts[1]
        end
      when "op"
        # TODO(should): map to be static somewhere (must match map in status.js)
        rc_map = {
          "success" => 0,
          "unknown" => 1,
          "args" => 2,
          "unimplemented" => 3,
          "perm" => 4,
          "installed" => 5,
          "configured" => 6,
          "not_running" => 7,
          "master" => 8,
          "failed_master" => 9
        }
        # we have something like:
        #  "op monitor:0 stonith-sbd success node-0"
        parts[1].sub!(":", "_")
        injections << "-i" << "#{parts[2]}_#{parts[1]}@#{parts[4]}=#{rc_map[parts[3]]}"
      when "ticket"
        # TODO(could): Warn if feature doesn't exist (or don't show ticket button in UI at all)
        if Util.has_feature?(:sim_ticket)
          case parts[2]
          when "grant"
            injections << "-g" << parts[1]
          when "revoke"
            injections << "-r" << parts[1]
          when "standby"
            injections << "-b" << parts[1]
          when "activate"
            injections << "-e" << parts[1]
          end
        end
      end
    end if params[:injections]
    f = File.new("#{Rails.root}/tmp/sim.info", "w")
    stdout = Util.safe_x("/usr/sbin/crm_simulate",
      "-S",
      "-L", # "live", but will be against shadow CIB
      "-G", "#{Rails.root}/tmp/sim.graph",
      "-D", "#{Rails.root}/tmp/sim.dot",
      *injections)
    f.write(stdout)
    f.close
    is_empty = true
    begin
      f = File.open("#{Rails.root}/tmp/sim.graph")
      if f.readline().match(/^<transition_graph.*[^\/]>$/)
        # Cheap test - if the first line is a non-closed transition_graph element,
        # we know it's not an empty graph.
        is_empty = false
      end
      f.close
    rescue Exception
      # TODO(could): actually handle potential failure of crm_simulate run
    end
   render :json => {
     :is_empty => is_empty
   }
  end

  # TODO(must): make sure dot is installed
  def sim_get
    case params[:file]
    when "info"
      send_data File.new("#{Rails.root}/tmp/sim.info").read,
        :type => "text/plain", :disposition => "inline"
    when "in"
      shadow_id = ENV["CIB_shadow"]
      ENV.delete("CIB_shadow")
      send_data Invoker.instance.cibadmin('-Ql'), :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
      ENV["CIB_shadow"] = shadow_id
    when "out"
      send_data Invoker.instance.cibadmin('-Ql'), :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
    when "graph"
      if params[:format] == "xml"
        send_data File.new("#{Rails.root}/tmp/sim.graph").read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
      else
        png, err, status = Util.capture3("/usr/bin/dot", "-Tpng", "#{Rails.root}/tmp/sim.dot")
        # TODO(must): check status.exitstatus
        send_data png, :type => "image/png", :disposition => "inline"
      end
    else
      head :not_found
    end
  end
end
