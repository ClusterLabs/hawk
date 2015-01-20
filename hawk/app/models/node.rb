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

class Node < Record
  attribute :id, String
  attribute :uname, String
  attribute :attrs, Hash
  attribute :utilization, Hash

  attribute :state, String
  attribute :maintenance, Boolean
  attribute :standby, Boolean

  def state
    # TODO(must): Fetch the current state?
    :online
  end

  def maintenance
    # TODO(must): Need more attribute checks?
    if attrs['maintenance'] and attrs['maintenance'] == 'on'
      true
    else
      false
    end
  end

  def standby
    # TODO(must): Need more attribute checks?
    if attrs['standby'] and attrs['standby'] == 'on'
      true
    else
      false
    end
  end

  protected

  class << self
    def instantiate(xml)
      record = allocate
      record.uname = xml.attributes['uname'] || ''

      record.attrs = if xml.elements['instance_attributes']
        vals = xml.elements['instance_attributes'].elements.collect do |e|
          [
            e.attributes['name'],
            e.attributes['value']
          ]
        end

        Hash[vals]
      else
        {}
      end

      record.utilization = if xml.elements['utilization']
        vals = xml.elements['utilization'].elements.collect do |e|
          [
            e.attributes['name'],
            e.attributes['value']
          ]
        end

        Hash[vals]
      else
        {}
      end

      if record.utilization.any?
        Util.safe_x('/usr/sbin/crm_simulate', '-LU').split('\n').each do |line|
          m = line.match(/^Remaining:\s+([^\s]+)\s+capacity:\s+(.*)$/)

          next unless m
          next unless m[1] == node.uname

          m[2].split(' ').each do |u|
            name, value = u.split('=', 2)

            if node.utilization.has_key? name
              node.utilization[name][:remaining] = value.to_i
            end
          end
        end
      end

      record
    end

    def cib_type
      :node
    end

    def ordered
      all.sort do |a, b|
        a.uname.natcmp(b.uname, true)
      end
    end

    # Since pacemaker started using corosync node IDs as the node ID attribute,
    # Record#find will fail when looking for nodes by their human-readable
    # name, so have to override here
    def find(id)
      begin
        super(id)
      rescue CibObject::RecordNotFound
        # Can't find by id attribute, try by uname attribute
        super(id, 'uname')
      end
    end
  end
end
