# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Resource < Record
  class CommandError < StandardError
  end

  attribute :object_type, Symbol
  attribute :state, Symbol
  attribute :managed, Boolean
  attribute :ops, Hash
  attribute :params, Hash
  attribute :meta, Hash
  attribute :running_on, Array
  attribute :failed_ops, Array

  def object_type
    self.class.to_s.downcase
  end

  def state
    cib_by_id(id)[:state] || :unknown
  end

  def managed
    cib_by_id(id)[:is_managed] || false
  end

  def ops
    @ops ||= {}
  end

  def params
    @params ||= {}
  end

  def meta
    @meta ||= {}
  end

  def running_on
    {}.tap do |lst|
      r = cib_by_id(id)
      if r.has_key? :children
        r[:children].each do |c|
          if c.has_key? :instances
            c[:instances].each do |name, info|
              [:master, :slave, :started, :pending].each do |rstate|
                if info[rstate]
                  info[rstate].each do |n|
                    lst[n[:node]] = rstate
                  end
                end
              end
            end
          end
        end
      elsif r.has_key? :instances
        r[:instances].each do |name, info|
          [:master, :slave, :started, :pending].each do |rstate|
            if info[rstate]
              info[rstate].each do |n|
                lst[n[:node]] = rstate
              end
            end
          end
        end
      end
    end
  end

  def failed_ops
    [].tap do |lst|
      r = cib_by_id(id)
      if r.has_key? :children
        r[:children].each do |c|
          if c.has_key? :instances
            c[:instances].each do |name, info|
              if info.has_key? :failed_ops
                lst.concat info[:failed_ops]
              end
            end
          end
        end
      elsif r.has_key? :instances
        r[:instances].each do |name, info|
          if info.has_key? :failed_ops
            lst.concat info[:failed_ops]
          end
        end
      end
    end
  end

  def start!
    Invoker.instance.run(
      "crm",
      "resource",
      "start",
      id
    )
  end

  def stop!
    Invoker.instance.run(
      "crm",
      "resource",
      "stop",
      id
    )
  end

  def promote!
    Invoker.instance.run(
      "crm",
      "resource",
      "promote",
      id
    )
  end

  def demote!
    Invoker.instance.run(
      "crm",
      "resource",
      "demote",
      id
    )
  end

  def manage!
    Invoker.instance.run(
      "crm",
      "resource",
      "manage",
      id
    )
  end

  def unmanage!
    Invoker.instance.run(
      "crm",
      "resource",
      "unmanage",
      id
    )
  end

  def unmigrate!
    Invoker.instance.run(
      "crm",
      "resource",
      "unmigrate",
      id
    )
  end

  def migrate!(node = nil)
    Invoker.instance.run(
      "crm",
      "resource",
      "migrate",
      id,
      node.to_s
    )
  end

  def cleanup!(node = nil)
    Invoker.instance.run(
      "crm",
      "resource",
      "cleanup",
      id,
      node.to_s
    )
  end

  class << self
    def all
      super(true)
    end

    def find(id, attr = 'id')
      rsc = super(id, attr)
      return rsc if rsc.is_a? Resource
      raise Cib::RecordNotFound, _("Not a resource")
    end

    def cib_type_fetch
      "configuration//*[self::resources or self::tags]/*"
    end
  end

  protected

  def cib_by_id(id)
    current_cib.resources_by_id[id] || {}
  end
end
