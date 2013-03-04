#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2010-1013 SUSE LLC, All Rights Reserved.
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

require 'rexml/document' unless defined? REXML::Document

class CrmConfig < CibObject

  attr_accessor :props

  # This *deliberately* only exposes cib-bootstrap-options, rsc-options
  # and op-options.  Sets with any other ID are ignored.
  def initialize
    @id = "cib-bootstrap-options"   # needed to fake rails MVC into working
    @props = {
      "crm_config"    => {},
      "rsc_defaults"  => {},
      "op_defaults"   => {}
    }

    xml = REXML::Document.new(Invoker.instance.cibadmin('-Ql', '--xpath', "//crm_config|//rsc_defaults|//op_defaults"))
    raise CibObject::CibObjectError, _('Unable to parse cibadmin output') unless xml.root

    load_props(xml.elements["//crm_config/cluster_property_set[@id='cib-bootstrap-options']"], "crm_config")
    load_props(xml.elements["//rsc_defaults/meta_attributes[@id='rsc-options']"], "rsc_defaults")
    load_props(xml.elements["//op_defaults/meta_attributes[@id='op-options']"], "op_defaults")

  end

  def all_props
    @all_props ||= {
      "crm_config" => {
        # This is loaded dynamically
      },
      # TODO(should): This is copied from app/models/primitive.rb, should consolidate
      "rsc_defaults"  => {
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
      },
      # TODO(should): This is copied from jquery.ui.oplist.js (modulo defaults), should consolidate
      # (note comments in jquery.ui.oplist.js about defaults etc.)
      "op_defaults" => {
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
    }

    if @all_props["crm_config"].empty?
      [ "pengine", "crmd", "cib"].each do |cmd|
        [ "/usr/lib64/heartbeat/#{cmd}", "/usr/lib/heartbeat/#{cmd}" ].each do |path|
          next unless File.executable?(path)
          xml = REXML::Document.new(%x[#{path} metadata 2>/dev/null])
          return unless xml.root
          xml.elements.each('//parameter') do |param|
            name = param.attributes['name']
            content   = param.elements['content']
            # TODO(should): select by language (en)
            shortdesc = param.elements['shortdesc'].text || ''
            longdesc  = param.elements['longdesc'].text || ''
            @all_props["crm_config"][name] = {
              :type       => content.attributes['type'],  # boolean, enum, integer, time
              :readonly   => false,
              :shortdesc  => shortdesc,
              :longdesc   => longdesc,
              :advanced   => (shortdesc.match(/advanced use only/i)) ||
                             (longdesc.match(/advanced use only/i)) ? true : false,
              :default    => content.attributes['default']
            }
            if @all_props["crm_config"][name][:type] == 'enum'
              m = longdesc.match(/Allowed values:(.*)/i)
              values = m[1].split(',').map {|v| v.strip}.select {|v| !v.empty?} if m
              # Yes, this next is paranoid.  But hey, we're parsing arbitrary text here...
              @all_props["crm_config"][name][:values] = values unless values.empty?
            end
          end
          break
        end
      end
      # These are meant to be read-only; should we hide them
      # in the editor?  grey them out? ...?
      ["cluster-infrastructure", "dc-version", "expected-quorum-votes"].each do |n|
        @all_props["crm_config"][n][:readonly] = true
      end
    end

    @all_props
  end

  private

  def load_props(elem, set)
    elem.elements.each("nvpair") do |nv|
      @props[set][nv.attributes["name"]] = nv.attributes["value"]
    end if elem
  end

end
