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
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

require 'rexml/document' unless defined? REXML::Document

class Node < CibObject
  include FastGettext::Translation

  @attributes = :uname, :attrs, :utilization
  attr_accessor *@attributes

  def initialize(attributes = nil)
    @uname = @id
    @attrs = {}
    @utilization = {}
    super
  end

  class << self

    # Since pacemaker started using corosync node IDs as the node ID
    # attribute, CibObject#find will fail when looking for nodes by
    # their human-readable name, so have to override here
    def find(id)
      begin
        super(id)
      rescue CibObject::RecordNotFound
        # Can't find by id attribute, try by uname attribute
        super(id, "uname")
      end
    end

    def instantiate(xml)
      node = allocate
      # TODO(should): Apparently this instance_variable_set business isn't necessary,
      # can just use node.uname, node.attrs etc...  Should change across all models. 
      node.instance_variable_set(:@uname, xml.attributes['uname'] || '')
      node.instance_variable_set(:@attrs, xml.elements['instance_attributes'] ?
        Hash[xml.elements['instance_attributes'].elements.collect {|e|
          [e.attributes['name'], e.attributes['value']] }] : {})
      node.instance_variable_set(:@utilization, xml.elements['utilization'] ?
        Hash[xml.elements['utilization'].elements.collect {|e|
          [e.attributes['name'], { :total => e.attributes['value'].to_i } ] }] : {})
      if (node.utilization.any?)
        Util.safe_x('/usr/sbin/crm_simulate', '-LU').split("\n").each do |line|
          m = line.match(/^Remaining:\s+([^\s]+)\s+capacity:\s+(.*)$/)
          next unless m
          next unless m[1] == node.uname
          m[2].split(' ').each do |u|
            pair = u.split('=')
            if node.utilization.has_key?(pair[0])
              node.utilization[pair[0]][:remaining] = pair[1].to_i
            end
          end
        end
      end
      node
    end
    
  end
end

