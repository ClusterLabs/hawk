# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class User < Record
  attribute :id, String
  attribute :roles, Array[String]

  validates :id,
    presence: { message: _('User ID is required') },
    format: { with: /\A[a-zA-Z0-9_-]+\z/, message: _('Invalid User ID') }

  def roles
    @roles ||= Array.new
  end

  protected

  def shell_syntax
    [].tap do |cmd|
      cmd.push "acl_target #{id}"

      roles.each do |role|
        cmd.push role
      end
    end.join(' ')
  end

  class << self
    def instantiate(xml)
      record = allocate

      xml.elements.each do |elem|
        if elem.name == 'role'
          record.roles.push elem.attributes['id']
        end
      end

      record
    end

    def cib_type
      :acl_target
    end
  end
end
