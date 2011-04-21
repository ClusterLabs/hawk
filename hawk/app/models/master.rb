#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., Tim Serong <tserong@novell.com>
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

class Master < CibObject
  include GetText

  attr_accessor :child, :meta

  def initialize(attributes = nil)
    @new_record = true
    @id         = nil
    @child      = ''
    @meta       = {}
    unless attributes.nil?
      ['id', 'child', 'meta'].each do |n|
        instance_variable_set("@#{n}".to_sym, attributes[n]) if attributes.has_key?(n)
      end
    end
  end

  def save
    if @id.match(/[^a-zA-Z0-9_-]/)
      error _('Invalid Resource ID "%{id}"') % { :id => @id }
    end

    @meta.each do |n,v|
      if v.index("'") && v.index('"')
        error _("Can't set meta attribute %{p}, because the value contains both single and double quotes") % { :p => n }
      end
    end

    if @child.empty?
      error _('No Master/Slave child specified')
    end

    return false if errors.any?

    if new_record?
      if CibObject.exists?(id)
        error _('The ID "%{id}" is already in use') % { :id => @id }
        return false
      end

      # TODO(must): Ensure child is sanitized
      cmd = "ms #{@id} #{@child}"
      unless @meta.empty?
        cmd += " meta"
        @meta.each do |n,v|
          if v.index("'")
            cmd += " #{n}=\"#{v}\""
          else
            cmd += " #{n}='#{v}'"
          end
        end
      end
      cmd += "\ncommit\n"

      result = Invoker.instance.crm_configure cmd
      unless result == true
        error _('Unable to create master/slave: %{msg}') % { :msg => result }
        return false
      end

      return true
    else
      # Saving an existing master
      unless CibObject.exists?(id, 'master')
        error _('Master/Slave ID "%{id}" does not exist') % { :id => @id }
        return false
      end

      begin
        merge_nvpairs(@xml, 'meta_attributes', @meta)

        Invoker.instance.cibadmin_replace @xml.to_s
      rescue NotFoundError, SecurityError, RuntimeError => e
        error e.message
        return false
      end

      return true
    end

    false  # Never reached
  end

  def update_attributes(attributes)
    @meta = {}
    # TODO(must): consolidate with initializes
    unless attributes.nil?
      ['meta'].each do |n|
        instance_variable_set("@#{n}".to_sym, attributes[n]) if attributes.has_key?(n)
      end
    end
    save
  end

  class << self

    def instantiate(xml)
      res = allocate
      res.instance_variable_set(:@child,  xml.elements['primitive|group'].attributes['id'])
      res.instance_variable_set(:@meta,   xml.elements['meta_attributes'] ?
        Hash[xml.elements['meta_attributes'].elements.collect {|e|
          [e.attributes['name'], e.attributes['value']] }] : {})
      res
    end

    def metadata
      # TODO(must): are other meta attributes for master valid?
      {
        :meta => {
          "is-managed" => {
            :type     => "boolean",
            :default  => "true"
          },
          "priority" => {
            :type     => "integer",
            :default  => "0"
          },
          "target-role" => {
            :type     => "enum",
            :default  => "Started",
            :values   => [ "Started", "Stopped", "Master" ]
          },
          # Default is number of nodes in cluster - this is a bit nasty...
          "clone-max" => {
            :type     => "integer",
            :default  => %x[cibadmin -Ql --scope nodes 2>/dev/null].scan('<node ').length
          },
          "clone-node-max" => {
            :type     => "integer",
            :default  => "1"
          },
          "notify" => {
            :type     => "boolean",
            :default  => "false"
          },
          "globally-unique" => {
            :type     => "boolean",
            :default  => "true"
          },
          "ordered" => {
            :type     => "boolean",
            :default  => "false"
          },
          "interleave" => {
            :type     => "boolean",
            :default  => "false"
          },
          "master-max" => {
            :type     => "integer",
            :default  => "1"
          },
          "master-node-max" => {
            :type     => "integer",
            :default  => "1"
          }
        }
      }
    end

  end

end

