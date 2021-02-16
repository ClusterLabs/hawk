# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class Resource < Record
  class CommandError < StandardError
  end

  attribute :object_type, Symbol
  attribute :sort_type, String
  attribute :state, Symbol
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
    if record.new_record && current_cib.live?
      cli = record.shell_syntax
      _out, err, rc = Invoker.instance.no_log do |i|
        i.crm_configure ['cib new', cli, 'verify', 'commit'].join("\n")
      end
      err.lines.each do |l|
        if l.start_with? "ERROR:"
          record.errors.add :base, l[7..-1]
          break
        end
      end if rc != 0
    end
  end

  def object_type
    self.class.to_s.downcase
  end

  def sort_type
    if @xml.name == 'primitive'
      agent_name
    else
      @xml.name
    end
  end

  def state
    cib_by_id(id)[:state] || :unknown
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
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "start", id) }
  end

  def stop!
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "stop", id) }
  end

  def promote!
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "promote", id) }
  end

  def demote!
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "demote", id) }
  end

  def maintenance!(on)
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "maintenance", id, on) }
  end

  def unmigrate!
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "unmigrate", id) }
  end

  def migrate!(node = nil)
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "migrate", id, node.to_s) }
  end

  def cleanup!(node = nil)
    Invoker.instance.no_log { |i| i.crm("-F", "resource", "cleanup", id, node.to_s) }
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
      "configuration//*[self::resources]/*"
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

  def unique_id!(other)
    m = /(.*)-(\d+)/.match(other)
    other = m[1] if m
    i = 1
    i = m[2].to_i + 1 if m
    i += 1 while current_cib.resources_by_id.key?("#{other}-#{i}")
    @id = "#{other}-#{i}"
  end

  def rsc_constraints
    outp = Util.safe_x('/usr/sbin/crm_resource', '--resource', "#{id}", '-A', '2>/dev/null')
    info = {}
    outp.each_line do |l|
      l.strip!
      next if l.blank? || l.start_with?('* ')
      m = l.match(/\s*: Node (\S+)\s+\(score=([^,]+), id=([^)]+)\)/)
      if m && !info.key?(m[3])
        info[m[3]] = { id: m[3], type: :location, score: m[2], other: m[1] }
      else
        m = l.match(/\s*(\S+)\s+\(score=([^,]+), id=([^)]+)\)/)
        if m && !info.key?(m[3])
          info[m[3]] = { id: m[3], type: :colocation, score: m[2], other: m[1] }
        end
      end
    end
    info.values
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
