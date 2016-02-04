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
  attribute :utilization, Hash
  attribute :running_on, Array
  attribute :failed_ops, Array

  validate do |record|
    # to validate a new record:
    # try making the shell form and running verify;commit in a temporary shadow cib in crm
    # if it fails, report errors
    if record.new_record
      cli = record.shell_syntax
      _out, err, rc = Invoker.instance.no_log do |i|
        i.crm_configure ['cib new', cli, 'verify', 'commit'].join("\n")
      end
      err.lines.each do |l|
        record.errors.add :base, l[7..-1] if l.start_with? "ERROR:"
      end if rc != 0
    end
  end

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

  def utilization
    @utilization ||= {}
  end

  def running_on
    rsc_is_running_on cib_by_id(id)
  end

  def failed_ops
    rsc_failed_ops cib_by_id(id)
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

    def help_text
      super.merge(
        id: {
          type: "string",
          shortdesc: _("Resource ID"),
          longdesc: _("Unique identifier for the resource. May not contain spaces."),
          default: ""
        }
      )
    end
  end

  protected

  def cib_by_id(id)
    current_cib.resources_by_id[id] || {}
  end

  def rsc_is_running_on(rsc)
    {}.tap do |lst|
      if rsc.key? :children
        rsc[:children].each do |c|
          lst.merge! rsc_is_running_on(c)
        end
      end
      if rsc.key? :instances
        rsc[:instances].each do |name, info|
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

  def rsc_failed_ops(rsc)
    [].tap do |lst|
      if rsc.key? :children
        rsc[:children].each do |c|
          lst.concat rsc_failed_ops(c)
        end
      end
      if rsc.key? :instances
        rsc[:instances].each do |_name, info|
          lst.concat(info[:failed_ops]) if info.key? :failed_ops
        end
      end
    end
  end
end
