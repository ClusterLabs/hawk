#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2014 SUSE LLC, All Rights Reserved.
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

class ResourcesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  before_filter :god_required, only: [:events]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Resource.ordered.to_json
      end
    end
  end










  def show
    @res = Resource.find params[:id]

    @op_history = {}

    # Primitives are the only things that can actually have op history and fail counts
    return unless @res.class == Primitive

    # Get fail counts and op history
    xml = REXML::Document.new(Invoker.instance.cibadmin('-Ql', '--xpath', '//status'))
    xml.elements.each("status/node_state") do |ns|
      n = ns.attributes["uname"]
      @op_history[n] = { :fail_count => 0, :ops => [] }
      ns.elements.each("transient_attributes/instance_attributes/nvpair") do |nv|
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
      # Note: this can only work for clone instances with pacemaker 1.1.8+ (as it's
      # dropped the instance number, which this selector relies upon)
      ns.elements.each("lrm/lrm_resources/lrm_resource[@id='#{params[:id]}']") do |lrm_resource|
        ops = []
        lrm_resource.elements.each("lrm_rsc_op") do |op|
          ops << op
        end
        # Same sort logic as in Cib model, minus special case for pending migrate ops
        ops.sort {|a,b|
          if a.attributes['call-id'].to_i != -1 && b.attributes['call-id'].to_i != -1
            a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
          elsif a.attributes['call-id'].to_i == -1
            1
          elsif b.attributes['call-id'].to_i == -1
            -1
          else
            Rails.logger.error "Inexplicable op sort error (this can't happen)"
            a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
          end
        }.each do |op|
          @op_history[n][:ops] << {
            :op => op.attributes['operation'],
            :call_id => op.attributes['call-id'].to_i,
            :rc_code => op.attributes['rc-code'].to_i,
            :interval => op.attributes['interval'].to_i,
            :exec_time => op.attributes['exec-time'].to_i,
            :queue_time => op.attributes['queue-time'].to_i,
            :exit_reason => op.attributes.has_key?('exit-reason') ? op.attributes['exit-reason'] : '',
            :last_rc_change => sane_time(op.attributes['last-rc-change']),
            :last_run => sane_time(op.attributes['last-run'])
          }
        end
      end
    end if xml.root
  end

  # Don't strictly need CIB for this...
  def events
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
    render
  end

  def sane_time(t)
    t = t.to_i
    if (t > 0)
      Time.at(t).strftime("%Y-%m-%d %H:%M:%S")
    else
      ""
    end
  end








  protected

  def set_title
    @title = _('Resources')
  end

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end
end
