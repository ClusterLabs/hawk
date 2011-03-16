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
  attr_accessor :r_class, :r_provider, :r_type, :params

  def initialize(attributes = nil)
    @new_record = true
    @id         = nil
    @r_class    = 'ocf'
    @r_provider = 'heartbeat'
    @r_type     = ''
    @params     = {}
    unless attributes.nil?
      ['id', 'r_class', 'r_provider', 'r_type', 'params'].each do |n|
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
        # The only thing we can actually change right now (2011-03-15)
        # are parameters (instance_attributes).

        p = @xml.elements['primitive']
        if @params.empty?
          # No parameters to set, get rid of
          # instance_attributes (if it exists)
          p.elements['instance_attributes'].remove if p.elements['instance_attributes']
        else
          # Get rid of any attributes that are no longer set
          if p.elements['instance_attributes']
            p.elements['instance_attributes'].elements.each {|e|
              e.remove unless @params.keys.include? e.attributes['name'] }
          else
            # Add new instance attributes child
            p.add_element 'instance_attributes', { 'id' => "#{p.attributes['id']}-instance_attributes" }
          end
          @params.each do |n,v|
            # update existing, or add new
            nvp = p.elements["instance_attributes/nvpair[@name=\"#{n}\"]"]
            if nvp
              nvp.attributes['value'] = v
            else
              p.elements['instance_attributes'].add_element 'nvpair', {
                'id' => "#{p.elements['instance_attributes'].attributes['id']}-#{n}",
                'name' => n,
                'value' => v
              }
            end
          end
        end

        # TODO(should): Really should only do this if we're
        # certain something has changed.
        Invoker.instance.cibadmin_replace @xml.to_s
      rescue StandardError => e
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
    # TODO(must): consolidate with initializes
    unless attributes.nil?
      ['id', 'r_class', 'r_provider', 'r_type', 'params'].each do |n|
        instance_variable_set("@#{n}".to_sym, attributes[n]) if attributes.has_key?(n)
      end
    end
    save
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

    def meta(c, p, t)
      m = { :parameters => {}, :actions => {} }
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
        m[:actions][e.attributes['name']] = {}
        ['timeout', 'interval', 'depth'].each do |a|
          m[:actions][e.attributes['name']][a.to_sym] = e.attributes[a] if e.attributes[a]
        end
      end
      m
    end
  end

end

