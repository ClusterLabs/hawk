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

# Shim to get similar behaviour as ActiveRecord

class CibObject
  # Thank you http://stackoverflow.com/questions/9138706/undefined-method-model-name-in-rails-3
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  # Declare as persisted, to get to_param etc. magic from ActiveModel
  def persisted?
    !new_record?
  end

  include FastGettext::Translation

  class CibObjectError < StandardError
  end

  class RecordNotFound < CibObjectError
  end
  
  class PermissionDenied < CibObjectError
  end

  # Need this to behave like an instance of ActiveRecord
  attr_reader :id

  def new_record?
    @new_record || false
  end

  def errors
    @errors ||= []
  end

  def save
    error _('Invalid Resource ID "%{id}"') % { :id => @id } unless @id.match(/^[a-zA-Z0-9_-]+$/)
    validate
    return false if errors.any?
    create_or_update
  end

  class << self

    # Check whether anything with the given ID exists, or for a specific
    # element with that ID if type is specified.  Note that we run as
    # hacluster, because we need to verify existence regardless of whether
    # the current user can actually see the object in quesion.
    def exists?(id, type='*')
      out = Util.safe_x('/usr/sbin/cibadmin', '-Ql', '--xpath', "//configuration//#{type}[@id='#{id}']").chomp
      !out.empty? && out != '<null>'
    end

    # Find a CIB object by ID and return an instance of the appropriate
    # class.  Note that if the current user doesn't have read access to
    # the primitive, it appears to result in CibObject::RecordNotFound,
    # due to the way the CIB ACL filtering works internally.
    # TODO(must): really, in the context this is used, we already have
    # a parsed CIB in the Cib object.  We should either *use* this, or
    # ensure CIB in Cib isn't parsed unless actually needed for the
    # status page.
    def find(id)
      begin
        xml = REXML::Document.new(Invoker.instance.cibadmin('-Ql', '--xpath',
          "//configuration//*[self::node or self::primitive or self::template or self::clone or self::group or self::master or self::rsc_order or self::rsc_colocation or self::rsc_location or self::rsc_ticket][@id='#{id}']"))
        raise CibObject::CibObjectError, _('Unable to parse cibadmin output') unless xml.root
        elem = xml.elements[1]
        obj = class_from_element_name(elem.name).instantiate(elem)
        obj.instance_variable_set(:@id, elem.attributes['id'])
        obj.instance_variable_set(:@xml, elem)
        obj
      rescue SecurityError => e
        raise CibObject::PermissionDenied, e.message
      rescue NotFoundError => e
        raise CibObject::RecordNotFound, e.message
      rescue RuntimeError => e
        raise CibObject::CibObjectError, e.message
      end
    end

    # Return all objects of a given type.  Pass get_children=true when
    # type is a parent element (see comment in function below for details).
    def all(type, get_children=false)
      begin
        xml = REXML::Document.new(Invoker.instance.cibadmin('-Ql', '--xpath', "//#{type}"))
        raise CibObject::CibObjectError, _('Unable to parse cibadmin output') unless xml.root
        # Now we may have children we want (which may be an empty set), e.g.:
        # when requesting "constraints", this works because there's always one
        # constraints element in the CIB.  It'd work the same if requesting 
        # resources or whatnot too.  Where it gets weird is if we want to
        # request all elements of, say, type "template" or "primitive".
        # In this case we either get back:
        #  - "<null>" (no matches, but also invalid XML, so throws NotFoundError,
        #    which is handled below).
        #  - a single element of the reqeusted type, in which case that needs
        #    to be returned as the only element in the array
        #  - multiple elements inside an <xpath-query> parent
        a = []
        parent = get_children || xml.root.name == "xpath-query" ? xml.elements[1] : xml
        parent.elements.each do |e|
          obj = class_from_element_name(e.name).instantiate(e)
          obj.instance_variable_set(:@id, e.attributes['id'])
          obj.instance_variable_set(:@xml, e)
          a << obj
        end
        a
      rescue SecurityError => e
        raise CibObject::PermissionDenied, e.message
      rescue NotFoundError => e
        # No objects of this type, this is fine - return empty array
        []
      rescue RuntimeError => e
        raise CibObject::CibObjectError, e.message
      end
    end

    private
    
    def class_from_element_name(name)
      @@map = {
        'node'            => Node,
        'primitive'       => Primitive,
        'template'        => Template,
        'clone'           => Clone,
        'group'           => Group,
        'master'          => Master,
        'rsc_order'       => Order,
        'rsc_colocation'  => Colocation,
        'rsc_location'    => Location,
        'rsc_ticket'      => Ticket
      }
      @@map[name]
    end
    
  end

  protected

  def error(msg)
    @errors ||= []
    @errors << msg
  end

  def initialize(attributes = nil)
    @new_record = true
    @id = nil
    set_attributes(attributes)
  end

  def set_attributes(attributes = nil)
    return if attributes.nil?
    ['id', *self.class.instance_variable_get('@attributes')].each do |n|
      instance_variable_set("@#{n}".to_sym, attributes[n]) if attributes.has_key?(n)
    end
  end

  # Override this to add extra validation on save (it's enough
  # to call 'error', no need to return anything in particular)
  def validate
  end

  def create_or_update
    result = new_record? ? create : update
    result != false
  end

  def update_attributes(attributes = nil)
    set_attributes(attributes)
    save  # must be defined in subclass
  end

  def merge_nvpairs(parent, list, attrs)
    if attrs.empty?
      # No attributes to set, get rid of the list (if it exists)
      parent.elements[list].remove if parent.elements[list]
    else
      # Get rid of any attributes that are no longer set
      if parent.elements[list]
        parent.elements[list].elements.each {|e|
          e.remove unless attrs.keys.include? e.attributes['name'] }
      else
        # Add new instance attributes child
        parent.add_element list, { 'id' => "#{parent.attributes['id']}-#{list}" }
      end
      attrs.each do |n,v|
        # update existing, or add new
        nvp = parent.elements["#{list}/nvpair[@name=\"#{n}\"]"]
        if nvp
          nvp.attributes['value'] = v
        else
          parent.elements[list].add_element 'nvpair', {
            'id' => "#{parent.elements[list].attributes['id']}-#{n}",
            'name' => n,
            'value' => v
          }
        end
      end
    end
  end

end
