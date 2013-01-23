#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2010 Novell Inc., Tim Serong <tserong@novell.com>
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

require 'rexml/document' unless defined? REXML::Document

class CrmConfig < CibObject

  private

  def load_meta(cmd)
    # TODO(should): make this static, don't load it every
    # time.  Do we need to re-load sometimes?  (Pacemaker
    # upgrade without restarting Hawk?)
    [ "/usr/lib64/heartbeat/#{cmd}", "/usr/lib/heartbeat/#{cmd}" ].each do |path|
      next unless File.executable?(path)
      xml = REXML::Document.new(%x[#{path} metadata 2>/dev/null])
      return unless xml.root
      xml.elements.each('//parameter') do |param|
        name = param.attributes['name'].to_sym
        content   = param.elements['content']
        # TODO(should): select by language (en)
        shortdesc = param.elements['shortdesc'].text || ''
        longdesc  = param.elements['longdesc'].text || ''
        @all_props[name] = {
          :type       => content.attributes['type'],  # boolean, enum, integer, time
          :readonly   => false,
          :shortdesc  => shortdesc,
          :longdesc   => longdesc,
          :advanced   => (shortdesc.match(/advanced use only/i)) ||
                         (longdesc.match(/advanced use only/i)) ? true : false,
          :default    => content.attributes['default']
        }
        if @all_props[name][:type] == 'enum'
          m = longdesc.match(/Allowed values:(.*)/i)
          values = m[1].split(',').map {|v| v.strip}.select {|v| !v.empty?} if m
          # Yes, this next is paranoid.  But hey, we're parsing arbitrary text here...
          @all_props[name][:values] = values unless values.empty?
        end
      end
      break
    end
    nil # Don't return anything
  end

  public

  attr_accessor :props, :all_props
  attr_accessor :rsc_defaults, :all_rsc_defaults
  attr_accessor :op_defaults, :all_op_defaults

  def initialize(parent_elem, id)
    @id = id

    @props     = {}
    @all_props = {}

    @rsc_defaults = {}
    # TODO(should): This is copied from app/models/primitive.rb, should consolidate
    @all_rsc_defaults = {
      "allow-migrate" => {
        :type     => "boolean",
        :default  => "false"
      },
      "is-managed" => {
        :type     => "boolean",
        :default  => "true"
      },
      "interval-origin" => {
        :type     => "integer",
        :default  => "0"
      },
      "migration-threshold" => {
        :type     => "integer",
        :default  => "0"
      },
      "priority" => {
        :type     => "integer",
        :default  => "0"
      },
      "multiple-active" => {
        :type     => "enum",
        :default  => "stop_start",
        :values   => [ "block", "stop_only", "stop_start" ]
      },
      "failure-timeout" => {
        :type     => "integer",
        :default  => "0"
      },
      "resource-stickiness" => {
        :type     => "integer",
        :default  => "0"
      },
      "target-role" => {
        :type     => "enum",
        :default  => "Started",
        :values   => [ "Started", "Stopped", "Master" ]
      },
      "restart-type" => {
        :type     => "enum",
        :default  => "ignore",
        :values   => [ "ignore", "restart" ]
      },
      "description" => {
        :type     => "string",
        :default  => ""
      }
    }

    @op_defaults = {}
    # TODO(should): This is copied from jquery.ui.oplist.js (modulo defaults), should consolidate
    # (note comments in jquery.ui.oplist.js about defaults etc.)
    @all_op_defaults = {
      "interval" => {
        :type     => "string",
        :default  => 0
      },
      "timeout" => {
        :type     => "string",
        :default  => "20"
      },
      "requires" => {
        :type     => "enum",
        :default  => "fencing",
        :values   => ["nothing", "quorum", "fencing"]
      },
      "enabled" => {
        :type     => "boolean",
        :default  => "true"
      },
      "role" => {
        :type     => "enum",
        :default  => "",
        :values   => ["Stopped", "Started", "Slave", "Master"]
      },
      "on-fail" => {
        :type     => "enum",
        :default  => "stop",
        :values   => ["ignore", "block", "stop", "restart", "standby", "fence"]
      },
      "start-delay" => {
        :type     => "string",
        :default  =>"0"
      },
      "interval-origin" => {
        :type     => "string",
        :default  => "0"
      },
      "record-pending" => {
        :type     => "boolean",
        :default  => "false"
      },
      "description" => {
        :type     => "string",
        :default  => ""
      }
    }

    load_meta 'pengine'
    load_meta 'crmd'
    load_meta 'cib'
    # These are meant to be read-only; should we hide them
    # in the editor?  grey them out? ...?
    [:"cluster-infrastructure", :"dc-version", :"expected-quorum-votes"].each do |n|
      @all_props[n][:readonly] = true
    end

    @elem = parent_elem.elements["cluster_property_set[@id='#{id}']"]
    # @elem will be nil here if there's no property set with that ID
    @elem.elements.each('nvpair') do |nv|
      # TODO(should): This is not smart enough to do anything
      # special with rules, scores etc.
      @props[nv.attributes['name'].to_sym] = nv.attributes['value']
    end if @elem

    # The next two are wrong in so many ways... (we shouldn't even bother
    # convoluting through cib for this class at all, to say nothing of what
    # I'm doing with "parent" - *gah*)

    # Note: not to_sym'ing names.  Should we be?

    @elem = parent_elem.parent.elements["rsc_defaults/meta_attributes[@id='rsc-options']"]
    @elem.elements.each('nvpair') do |nv|
      @rsc_defaults[nv.attributes['name']] = nv.attributes['value']
    end if @elem

    @elem = parent_elem.parent.elements["op_defaults/meta_attributes[@id='op-options']"]
    @elem.elements.each('nvpair') do |nv|
      @op_defaults[nv.attributes['name']] = nv.attributes['value']
    end if @elem

  end

end
