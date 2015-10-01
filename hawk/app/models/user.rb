# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class User < Record
  attribute :id, String
  attribute :roles, Array[String]
  attr_accessor :schema_version

  validates :id,
    presence: { message: _('ACL target ID is required') },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _('Invalid ACL target ID') }

  validates :roles, presence: { message: _('At least one role is required') }

  def roles
    @roles ||= Array.new
  end

  protected

  def shell_syntax
    cmdname = schema_version < 2.0 ? "acl_user" : "acl_target"

    [].tap do |cmd|
      cmd.push "#{cmdname} #{id}"

      roles.each do |role|
        cmd.push role
      end
    end.join(' ')
  end

  def schema_version
    @schema_version ||= Util.acl_version
  end

  class << self
    def instantiate(xml)
      record = allocate

      xml.elements.each do |elem|
        if elem.name == 'role' || elem.name == 'role_ref'
          record.roles.push elem.attributes['id']
        end
      end

      record
    end

    def cib_type
      :acl_target
    end

    def cib_type_fetch
      '*[self::acl_user or self::acl_target]'
    end

    def cib_type_write
      '*[self::acl_user or self::acl_target]'
    end
  end
end
