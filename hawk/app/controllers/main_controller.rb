#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2012 Novell Inc., All Rights Reserved.
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

require 'util'
require 'rexml/document' unless defined? REXML::Document

class MainController < ApplicationController
  before_filter :login_required

  private

  # Invoke some command, returning OK or JSON error as appropriate
  def invoke(*cmd)
    result = Invoker.instance.run(*cmd)
    if result == true
      head :ok
    else
      render :status => 500, :json => {
        :error  => _('%{cmd} failed (status: %{status})') % { :cmd => cmd.join(' '), :status => result[0] },
        :stderr => result[1]
      }
    end
  end

  public

  # Render cluster status by default
  # (can't just render :action => 'status',
  # or we don't get the instance variables)
  def index
    redirect_to :action => 'status'
  end

  def gettext
    render :partial => 'gettext'
  end

  def status
    @title = _('Cluster Status')
  end

  # TODO(should): Node ops, resource ops, arguably belong in separate
  # node and resource controllers/models.  Note this would change the
  # class hierarchy for primitve, group, etc., e.g.:
  #   Primitive < Resource < CibObject
  # (see also related comment in config/routes.rb)

  # standby/online (op validity guaranteed by routes)
  def node_standby
    if params[:node]
      invoke 'crm_attribute', '-N', params[:node], '-n', 'standby', '-v', params[:op] == 'standby' ? 'on' : 'off', '-l', 'forever'
    else
      render :status => 400, :json => {
        :error => _('Required parameter "node" not specified')
      }
    end
  end

  def node_fence
    if params[:node]
      invoke 'crm_attribute', '-t', 'status', '-U', params[:node], '-n', 'terminate', '-v', 'true'
    else
      render :status => 400, :json => {
        :error => _('Required parameter "node" not specified')
      }
    end
  end

#  def node_mark
#    head :ok
#  end

  # start, stop, etc. (op validity guaranteed by routes)
  # TODO(should): exceptions to handle missing params
  def resource_op
    if params[:resource]
      invoke 'crm', 'resource', params[:op], params[:resource]
    else
      render :status => 400, :json => {
        :error => _('Required parameter "resource" not specified')
      }
    end
  end

  def resource_migrate
    if params[:resource] && params[:node]
      invoke 'crm', 'resource', 'migrate', params[:resource], params[:node]
    else
      render :status => 400, :json => {
        :error => _('Required parameters "resource" and "node" not specified')
      }
    end
  end

  def resource_delete
    if params[:resource]
      result = Invoker.instance.crm 'configure', 'delete', params[:resource]
      if result == true
        head :ok
      else
        render :status => 500, :json => {
          # Strictly, this may not be an error (see Invoker::crm comments)
          :error  => _('Error deleting resource'),
          :stderr => result
        }
      end
    else
      render :status => 400, :json => {
        :error => _('Required parameter "resource" not specified')
      }
    end
  end

  # TODO(must): these both need exception handler for invoker runs
  # TODO(must): only one user at a time can run sims (they stomp on each other)
  def sim_reset
    f = File.new("#{RAILS_ROOT}/tmp/sim.in", "w")
    f.write(Invoker.instance.cibadmin('-Ql'))
    f.close
    head :ok
  end

  def sim_run
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
    end
    f = File.new("#{RAILS_ROOT}/tmp/sim.info", "w")
    # TODO(must): Bloody loses transition summary (it's on STDOUT)
    stdout = Util.safe_x("/usr/sbin/crm_simulate",
      "-S",
      "-x", "#{RAILS_ROOT}/tmp/sim.in",
      "-O", "#{RAILS_ROOT}/tmp/sim.out",
      "-G", "#{RAILS_ROOT}/tmp/sim.graph",
      "-D", "#{RAILS_ROOT}/tmp/sim.dot",
      *injections)
    f.write(stdout)
    f.close
    is_empty = true
    begin
      f = File.open("#{RAILS_ROOT}/tmp/sim.graph")
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
      info = { :mods => "", :summary => "", :exec => "" }
      section = nil
      File.new("#{RAILS_ROOT}/tmp/sim.info").read.split(/\n/).each do |line|
        case line
          when /^Performing requested modifications/i
            section = :mods
#          when /^Transition Summary/i
#            section = :summary
          when /^Executing cluster transition/i
            section = :exec
          when /^\s*$/
            section = nil
        end
        next unless section
        info[section] += line + "\n"
      end
      send_data [info[:mods], info[:summary], info[:exec]].select{|s| !s.empty?}.join("\n"),
        :type => "text/plain", :disposition => "inline"
    when "in"
      send_data File.new("#{RAILS_ROOT}/tmp/sim.in").read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
    when "out"
      send_data File.new("#{RAILS_ROOT}/tmp/sim.out").read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
    when "graph"
      if params[:format] == "xml"
        send_data File.new("#{RAILS_ROOT}/tmp/sim.graph").read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
      else
        stdin, stdout, stderr, thread = Util.popen3("/usr/bin/dot", "-Tpng", "#{RAILS_ROOT}/tmp/sim.dot")
        stdin.close
        png = stdout.read
        stdout.close
        stderr.close
        # TODO(must): check thread.value.exitstatus
        send_data png, :type => "image/png", :disposition => "inline"
      end
    else
      head :not_found
    end
  end

end
