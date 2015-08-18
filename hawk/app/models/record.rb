# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Record < Tableless
  class CibObjectError < StandardError
  end

  class RecordNotFound < CibObjectError
  end

  class PermissionDenied < CibObjectError
  end

  class << self
    # Check whether anything with the given ID exists, or for a specific element
    # with that ID if type is specified.  Note that we run as hacluster, because
    # we need to verify existence regardless of whether the current user can
    # actually see the object in quesion.
    def exists?(id, type = '*')
      result = Util.safe_x(
        '/usr/sbin/cibadmin',
        '-Ql',
        '--xpath',
        "//configuration//#{type}[@id='#{id}']"
      ).chomp

      !result.empty? && result != '<null>'
    end

    # Find a CIB object by ID and return an instance of the appropriate class.
    # Note that if the current user doesn't have read access to the primitive,
    # it appears to result in CibObject::RecordNotFound, due to the way the
    # CIB ACL filtering works internally.
    #
    # TODO(must): really, in the context this is used, we already have a parsed
    # CIB in the Cib object. We should either *use* this, or ensure CIB in
    # Cib isn't parsed unless actually needed for the status page.
    def find(id, attr = 'id')
      begin
        xml = REXML::Document.new(
          Invoker.instance.cibadmin(
            '-Ql',
            '--xpath',
            "//configuration//*[self::node or self::primitive or self::template or self::clone or self::group or self::master or self::rsc_order or self::rsc_colocation or self::rsc_location or self::rsc_ticket or self::acl_role or self::acl_target or self::tag][@#{attr}='#{id}']"
          )
        )

        unless xml.root
          raise CibObject::CibObjectError, _('Unable to parse cibadmin output')
        end

        elem = xml.elements[1]

        obj = class_from_element_name(elem.name).instantiate(elem)
        obj.id = elem.attributes['id']
        obj.xml = elem

        obj
      rescue SecurityError => e
        raise CibObject::PermissionDenied, e.message
      rescue NotFoundError => e
        raise CibObject::RecordNotFound, e.message
      rescue RecordNotFound => e
        raise CibObject::RecordNotFound, e.message
      rescue RuntimeError => e
        raise CibObject::CibObjectError, e.message
      end
    end

    # Return all objects of a given type. Pass get_children = true when type is
    # a parent element (see comment in function below for details).
    def all(get_children = false)
      begin
        require 'rexml/document'

        xml = REXML::Document.new(
          Invoker.instance.cibadmin('-Ql', '--xpath', "//#{cib_type_fetch}".shellescape)
        )

        unless xml.root
          raise CibObject::CibObjectError, _('Unable to parse cibadmin output')
        end

        #
        # Now we may have children we want (which may be an empty set), e.g.:
        # when requesting "constraints", this works because there's always one
        # constraints element in the CIB.  It'd work the same if requesting
        # resources or whatnot too.  Where it gets weird is if we want to
        # request all elements of, say, type "template" or "primitive".
        #
        # In this case we either get back:
        #  - "<null>" (no matches, but also invalid XML, so throws NotFoundError,
        #    which is handled below).
        #
        #  - a single element of the reqeusted type, in which case that needs
        #    to be returned as the only element in the array
        #
        #  - multiple elements inside an <xpath-query> parent
        #

        [].tap do |result|
          parent = if get_children or xml.root.name == "xpath-query"
            xml.elements[1]
          else
            xml
          end

          parent.elements.each do |elem|
            obj = class_from_element_name(elem.name).instantiate(elem)
            obj.id = elem.attributes['id']
            obj.xml = elem

            result << obj
          end
        end
      rescue SecurityError => e
        raise CibObject::PermissionDenied, e.message
      rescue NotFoundError => e
        []
      rescue RecordNotFound => e
        []
      rescue RuntimeError => e
        raise CibObject::CibObjectError, e.message
      end
    end

    def ordered
      all.sort do |a, b|
        a.id.natcmp(b.id, true)
      end
    end

    def cib_type
      nil
    end

    def cib_type_fetch
      cib_type
    end

    def cib_type_write
      cib_type
    end

    protected

    def class_from_element_name(name)
      @map ||= {
        node: Node,
        primitive: Primitive,
        template: Template,
        clone: Clone,
        group: Group,
        master: Master,
        rsc_order: Order,
        rsc_colocation: Colocation,
        rsc_location: Location,
        rsc_ticket: Ticket,
        acl_role: Role,
        acl_target: User,
        tag: Tag
      }

      @map[name.to_sym]
    end
  end

  attr_accessor :id
  attr_accessor :xml










  def merge_ocf_check_level(op, v)
    unless v
      # No OCF_CHECK_LEVEL set, remove it from the XML if present
      cl = op.elements['instance_attributes/nvpair[@name="OCF_CHECK_LEVEL"]']
      cl.remove if cl

      return
    end

    unless op.elements['instance_attributes']
      op.add_element(
        'instance_attributes',
        {
          'id' => "#{op.attributes['id']}-instance_attributes"
        }
      )
    end

    nvp = op.elements['instance_attributes/nvpair[@name="OCF_CHECK_LEVEL"]']

    if nvp
      nvp.attributes['value'] = v
    else
      op.elements['instance_attributes'].add_element(
        'nvpair',
        {
          'id' => "#{op.attributes['id']}-instance_attributes-OCF_CHECK_LEVEL",
          'name' => 'OCF_CHECK_LEVEL',
          'value' => v
        }
      )
    end
  end

  def merge_operations(attrs)
    if attrs.empty?
      # No operations to set, get rid of the list (if it exists)
      xml.elements['operations'].remove if xml.elements['operations']
    else
      # Get rid of any operations that are no longer set
      if xml.elements['operations']
        xml.elements['operations'].elements.each do |el|
          el.remove unless attrs[el.attributes['name']] && attrs[el.attributes['name']][el.attributes['interval']]
        end
      else
        xml.add_element 'operations'
      end

      # Write new operations or update existing ones
      attrs.each do |op_name, instances|
        instances.each do |i,attrlist|
          attrlist['interval'] = '0' unless attrlist.keys.include?('interval')
          op = xml.elements["operations/op[@name=\"#{op_name}\" and @interval=\"#{attrlist['interval']}\"]"]

          unless op
            op = xml.elements['operations'].add_element('op', {
              'id' => "#{xml.attributes['id']}-#{op_name}-#{attrlist['interval']}",
              'name' => op_name
            })
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










  def merge_nvpairs(list, attrs)
    if attrs.empty?
      # No attributes to set, get rid of the list (if it exists)
      xml.elements[list].remove if xml.elements[list]
    else
      # Get rid of any attributes that are no longer set
      if xml.elements[list]
        xml.elements[list].elements.each do |el|
          el.remove unless attrs.keys.include? el.attributes['name']
        end
      else
        xml.add_element(list, {
          "id" => "#{xml.attributes["id"]}-#{list}"
        })
      end

      # Write new attributes or update existing ones
      attrs.each do |n, v|
        nvp = xml.elements["#{list}/nvpair[@name=\"#{n}\"]"]

        if nvp
          nvp.attributes["value"] = v
        else
          xml.elements[list].add_element("nvpair", {
            "id" => "#{xml.elements[list].attributes['id']}-#{n}",
            "name" => n,
            "value" => v
          })
        end
      end
    end
  end

  protected

  def create
    if self.class.exists? self.id
      errors.add :base, _('The ID "%{id}" is already in use') % { id: self.id }
      return false
    end

    result = Invoker.instance.crm_configure shell_syntax

    unless result == true
      errors.add :base, _('Unable to create: %{msg}') % { msg: result }
      return false
    end

    true
  end

  def update
    unless self.class.exists?(self.id, self.class.cib_type_write)
      errors.add :base, _('The ID "%{id}" does not exist') % { id: self.id }
      return false
    end

    result = Invoker.instance.crm_configure_load_update shell_syntax

    unless result == true
      errors.add :base, _('Unable to update: %{msg}') % { msg: result }
      return false
    end

    true
  end
end
