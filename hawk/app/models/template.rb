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

require 'natcmp'

require 'rexml/document' unless defined? REXML::Document

# TODO(must): asside from meta & classes/providers, essentially a dupe
# of Primitive.  Must consolidate.

class Template < CibObject
  include FastGettext::Translation

  # Using r_class to avoid collision with class reserved word.
  # Using r_provider and r_type for consistency with r_class.
  @attributes = :r_class, :r_provider, :r_type, :params, :ops, :meta
  attr_accessor *@attributes

  def initialize(attributes = nil)
    @r_class    = 'ocf'
    # @r_provider must always be empty by default, else it'll override
    # empty providers for e.g.: STONITH resources, resulting in bogus
    # resource creation errors.
    @r_provider = ''
    @r_type     = ''
    @params     = {}
    @ops        = {}
    @meta       = {}
    super
  end

  def create
    @params.each do |n,v|
      if v.index("'") && v.index('"')
        error _("Can't set parameter %{p}, because the value contains both single and double quotes") % { :p => n }
      end
    end

    @ops.each do |op,instances|
      instances.each do |i, attrlist|
        attrlist.each do |n,v|
          if v.index("'") && v.index('"')
            error _("Can't set op %{o} attribute {%a}, because the value contains both single and double quotes") % { :o => op, :a => n }
          end
        end
      end
    end

    @meta.each do |n,v|
      if v.index("'") && v.index('"')
        error _("Can't set meta attribute %{p}, because the value contains both single and double quotes") % { :p => n }
      end
    end

    return false if errors.any?

    if CibObject.exists?(id)
      error _('The ID "%{id}" is already in use') % { :id => @id }
      return false
    end

    # TODO(must): Ensure r_class, r_provider and r_type are sanitized
    provider = @r_provider.empty? ? '' : @r_provider + ':'
    cmd = "rsc_template #{@id} #{@r_class}:#{provider}#{@r_type}"
    unless @params.empty?
      cmd += " params"
      @params.each do |n,v|
        if v.index("'")
          cmd += " #{n}=\"#{v}\""
        else
          cmd += " #{n}='#{v}'"
        end
      end
    end
    unless @ops.empty?
      @ops.each do |op, instances|
        instances.each do |i, attrlist|
          cmd += " op #{op}"
          attrlist.each do |n,v|
            if v.index("'")
              cmd += " #{n}=\"#{v}\""
            else
              cmd += " #{n}='#{v}'"
            end
          end
        end
      end
    end
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

    result = Invoker.instance.crm_configure cmd
    unless result == true
      error _('Unable to create resource: %{msg}') % { :msg => result }
      return false
    end

    true
  end

  def update
    # Saving an existing template
    unless CibObject.exists?(id, 'template')
      error _('Resource ID "%{id}" does not exist') % { :id => @id }
      return false
    end

    begin
      merge_nvpairs(@xml, 'instance_attributes', @params)
      merge_ops(@xml, @ops)
      merge_nvpairs(@xml, 'meta_attributes', @meta)

      # TODO(should): Really should only do this if we're
      # certain something has changed.
      Invoker.instance.cibadmin_replace @xml.to_s
    rescue NotFoundError, SecurityError, RuntimeError => e
      error e.message
      return false
    end

    true
  end

  def update_attributes(attributes)
    # Need to explicitly initialize this in case it's not passed
    # in ('save' method assumes @params is sane)
    @params = {}
    @ops = {}
    @meta = {}
    super
  end

  # This is somewhat similar to CibObject::merge_nvpairs
  def merge_ops(parent, ops)
    if ops.empty?
      parent.elements['operations'].remove if parent.elements['operations']
    else
      if parent.elements['operations']
        parent.elements['operations'].elements.each {|e|
          e.remove unless ops[e.attributes['name']] && ops[e.attributes['name']][e.attributes['interval']] }
      else
        parent.add_element 'operations'
      end
      ops.each do |op_name,instances|
        instances.each do |i,attrlist|
          # Everything needs an interval
          attrlist['interval'] = '0' unless attrlist.keys.include?('interval')
          op = parent.elements["operations/op[@name=\"#{op_name}\" and @interval=\"#{attrlist['interval']}\"]"]
          unless op
            op = parent.elements['operations'].add_element 'op', {
              'id' => "#{parent.attributes['id']}-#{op_name}-#{attrlist['interval']}",
              'name' => op_name
            }
          end
          merge_ocf_check_level(op, attrlist.delete("OCF_CHECK_LEVEL"))
          op.attributes.each do |n,v|
            op.attributes.delete(n) unless n == 'id' || n == 'name' || attrlist.keys.include?(n)
          end
          attrlist.each do |n,v|
            op.attributes[n] = v
          end
        end
      end
    end
  end

  class << self

    def instantiate(xml)
      # TODO(must): cope with missing/invalid class, type etc.
      # TODO(must): this may not handle multiple sets of instance attributes
      # TODO(should): do something sane with "invalid" (unknown) instance attributes
      res = allocate
      res.instance_variable_set(:@r_class,    xml.attributes['class'] || '')
      res.instance_variable_set(:@r_provider, xml.attributes['provider'] || '')
      res.instance_variable_set(:@r_type,     xml.attributes['type'] || '')
      res.instance_variable_set(:@params,     xml.elements['instance_attributes'] ?
        Hash[xml.elements['instance_attributes'].elements.collect {|e|
          [e.attributes['name'], e.attributes['value']] }] : {})
      # This bit is suspiciously similar to the action bit of metadata()
      ops = {}
      xml.elements['operations'].elements.each do |e|
        name = e.attributes['name']
        ops[name] = [] unless ops[name]
        op = Hash[e.attributes.collect{|a| a.to_a}]
        op.delete 'name'
        op.delete 'id'
        if name == "monitor"
          # special case for OCF_CHECK_LEVEL
          cl = e.elements['instance_attributes/nvpair[@name="OCF_CHECK_LEVEL"]']
          op["OCF_CHECK_LEVEL"] = cl.attributes['value'] if cl
        end
        ops[name].push op
      end if xml.elements['operations']
      res.instance_variable_set(:@ops,        ops)
      res.instance_variable_set(:@meta,       xml.elements['meta_attributes'] ?
        Hash[xml.elements['meta_attributes'].elements.collect {|e|
          [e.attributes['name'], e.attributes['value']] }] : {})
      res
    end

    def all
      super "template"
    end
  end
end
