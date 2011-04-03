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

require 'natcmp'

require 'rexml/document' unless defined? REXML::Document

class Primitive < CibObject
  include GetText

  # Using r_class to avoid collision with class reserved word.
  # Using r_provider and r_type for consistency with r_class.
  attr_accessor :r_class, :r_provider, :r_type, :params, :ops, :meta

  def initialize(attributes = nil)
    @new_record = true
    @id         = nil
    @r_class    = 'ocf'
    @r_provider = 'heartbeat'
    @r_type     = ''
    @params     = {}
    @ops        = {}
    @meta       = {}
    unless attributes.nil?
      ['id', 'r_class', 'r_provider', 'r_type', 'params', 'ops', 'meta'].each do |n|
        instance_variable_set("@#{n}".to_sym, attributes[n]) if attributes.has_key?(n)
      end
    end
  end

  def save
    if @id.match(/[^a-zA-Z0-9_-]/)
      error _('Invalid Resource ID "%{id}"') % { :id => @id }
    end

    # TODO(must): This error is only true for initial creation (using crm shell)
    @params.each do |n,v|
      if v.index("'") && v.index('"')
        error _("Can't set parameter %{p}, because the value contains both single and double quotes") % { :p => n }
      end
    end

    @ops.each do |op,attrlist|
      attrlist.each do |n,v|
        if v.index("'") && v.index('"')
          error _("Can't set op %{o} attribute {%a}, because the value contains both single and double quotes") % { :o => op, :a => n }
        end
      end
    end

    @meta.each do |n,v|
      if v.index("'") && v.index('"')
        error _("Can't set meta attribute %{p}, because the value contains both single and double quotes") % { :p => n }
      end
    end

    return false if errors.any?

    if new_record?
      if CibObject.id_exists?(id)
        error _('The ID "%{id}" is already in use') % { :id => @id }
        return false
      end

      # TODO(must): Ensure r_class, r_provider and r_type are sanitized
      provider = @r_provider.empty? ? '' : @r_provider + ':'
      cmd = "primitive #{@id} #{@r_class}:#{provider}#{@r_type}"
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
        @ops.each do |op, attrlist|
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
        error _('Unable to create resource: %{msg}') % { :msg => result }
        return false
      end

      return true

    else
      # Saving an existing primitive
      unless Primitive.exists?(id)
        error _('Resource ID "%{id}" does not exist') % { :id => @id }
        return false
      end

      begin
        p = @xml.elements['primitive']
        merge_nvpairs(p, 'instance_attributes', @params)
        merge_ops(p, @ops)
        merge_nvpairs(p, 'meta_attributes', @meta)

        # TODO(should): Really should only do this if we're
        # certain something has changed.
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
    # Need to explicitly initialize this in case it's not passed
    # in ('save' method assumes @params is sane)
    @params = {}
    @ops = {}
    @meta = {}
    # TODO(must): consolidate with initializes
    unless attributes.nil?
      ['id', 'r_class', 'r_provider', 'r_type', 'params', 'ops', 'meta'].each do |n|
        instance_variable_set("@#{n}".to_sym, attributes[n]) if attributes.has_key?(n)
      end
    end
    save
  end

  # This is remarkably cimilar to CibObject::merge_nvpairs
  def merge_ops(parent, ops)
    if ops.empty?
      parent.elements['operations'].remove if parent.elements['operations']
    else
      if parent.elements['operations']
        parent.elements['operations'].elements.each {|e|
          e.remove unless ops.keys.include? e.attributes['name'] }
      else
        parent.add_element 'operations'
      end
      ops.each do |op_name,attrlist|
        # Everything needs an interval
        attrlist['interval'] = '0' unless attrlist.keys.include?('interval')
        op = parent.elements["operations/op[@name=\"#{op_name}\"]"]
        unless op
          op = parent.elements['operations'].add_element 'op', {
            'id' => "#{parent.attributes['id']}-#{op_name}-#{attrlist['interval']}",
            'name' => op_name
          }
        end
        op.attributes.each do |n,v|
          op.attributes.delete(n) unless n == 'id' || n == 'name' || attrlist.keys.include?(n)
        end
        attrlist.each do |n,v|
          op.attributes[n] = v
        end
      end
    end
  end

  class << self

    # Check whether a primitive with the given ID exists
    # Note that we run as hacluster, because we need to verify existence
    # regardless of whether the current user can actually see the object
    # in quesion.
    def exists?(id)
      # TODO(must): sanitize ID
      %x[/usr/sbin/cibadmin -Ql --xpath '//primitive[@id="#{id}"]' 2>/dev/null].index('<primitive') ? true : false
    end

    # Find a primitive by ID and return it.  Note that if the current
    # user doesn't have read access to the primitive, it appears to
    # result in CibObject::RecordNotFound, due to the way the CIB ACL
    # filtering works internally.
    def find(id)
      begin
        xml = REXML::Document.new(Invoker.instance.cibadmin('-Ql', '--xpath', "//primitive[@id='#{id}']"))
        raise CibObject::CibObjectError, _('Unable to parse cibadmin output') unless xml.root

        # TODO(must): cope with missing/invalid class, type etc.
        # TODO(must): this may not handle multiple sets of instance attributes
        # TODO(should): do something sane with "invalid" (unknown) instance attributes
        p = xml.elements['primitive']
        res = allocate
        res.instance_variable_set(:@id, id)
        res.instance_variable_set(:@r_class,    p.attributes['class'] || '')
        res.instance_variable_set(:@r_provider, p.attributes['provider'] || '')
        res.instance_variable_set(:@r_type,     p.attributes['type'] || '')
        res.instance_variable_set(:@params,     p.elements['instance_attributes'] ?
          Hash[p.elements['instance_attributes'].elements.collect {|e|
            [e.attributes['name'], e.attributes['value']] }] : {})
        res.instance_variable_set(:@ops,        p.elements['operations'] ?
          Hash[p.elements['operations'].elements.collect {|e|
            [e.attributes['name'], Hash[
              e.attributes.collect.select {|n| n[0] != 'name' && n[0] != 'id' }]
            ] }] : {})
        res.instance_variable_set(:@meta,       p.elements['meta_attributes'] ?
          Hash[p.elements['meta_attributes'].elements.collect {|e|
            [e.attributes['name'], e.attributes['value']] }] : {})
        res.instance_variable_set(:@xml, xml)
        res
      rescue SecurityError => e
        raise CibObject::PermissionDenied, e.message
      rescue NotFoundError => e
        raise CibObject::RecordNotFound, e.message
      rescue RuntimeError => e
        raise CibObject::CibObjectError, e.message
      end
    end

    def classes_and_providers
      @@classes_and_providers ||= begin
        cp = {
          :r_classes   => [],
          :r_providers => {}
        }
        all_classes = %x[/usr/sbin/crm ra classes].split(/\n/).sort {|a,b| a.natcmp(b, true)}
        # Cheap hack to get rid of heartbeat class if there's no RAs of that type present
        all_classes.delete('heartbeat') unless File.exists?('/etc/ha.d/resource.d')
        all_classes.each do |c|
          if m = c.match('(.*)/(.*)')
            c = m[1].strip
            cp[:r_providers][c] = m[2].strip.split(' ').sort {|a,b| a.natcmp(b, true)}
          end
          cp[:r_classes].push c
        end
        cp
      end
    end

    def types(c, p='')
      @@r_types ||= Util.safe_x('/usr/sbin/crm', 'ra', 'list', c, p).split(/\s+/).sort {|a,b| a.natcmp(b, true)}
    end

    def metadata(c, p, t)
      m = {
        :parameters => {},
        :ops => {},
        :meta => {
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
      }
      return m if c.empty? or t.empty?
      p = 'NULL' if p.empty?
      xml = REXML::Document.new(Util.safe_x('/usr/sbin/lrmadmin', '-M', c, t, p, 'meta'))
      return m unless xml.root
      xml.elements.each('//parameter') do |e|
        m[:parameters][e.attributes['name']] = {
          :type     => e.elements['content'].attributes['type'],
          :default  => e.elements['content'].attributes['default'],
          :required => e.attributes['required'].to_i == 1 ? true : false
        }
      end
      xml.elements.each('//action') do |e|
        m[:ops][e.attributes['name']] = {}
        ['timeout', 'interval'].each do |a|
          if e.attributes[a]
            m[:ops][e.attributes['name']][a.to_sym] = e.attributes[a]
          else
            # There's at least one case (ocf:ocfs2:o2cb) where the
            # monitor op doesn't specify an interval, so we set a
            # "reasonable" default
            m[:ops][e.attributes['name']][a.to_sym] = "20"
          end
        end
      end
      m
    end
  end

end

