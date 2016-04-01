# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

require 'util'
require 'cibtools'
require 'natcmp'
require 'rexml/document' unless defined? REXML::Document
require 'rexml/xpath' unless defined? REXML::XPath

class Cib
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include FastGettext::Translation
  include Rails.application.routes.url_helpers # needed for routes

  class CibError < StandardError
    def initialize(message = nil, data = nil)
      super(message)
      @redirect_to = data.nil? ? nil : data[:redirect_to]
    end

    def head
      :bad_request
    end

    def redirect!(or_else)
      if @redirect_to.blank?
        or_else
      else
        @redirect_to
      end
    end
  end

  class RecordNotFound < CibError
    def head
      :not_found
    end
  end

  class PermissionDenied < CibError
    def head
      :forbidden
    end
  end

  class NotAuthenticated < CibError
    def head
      :forbidden
    end
  end

  attr_reader :id
  attr_reader :dc
  attr_reader :epoch
  attr_reader :nodes
  attr_reader :resources
  attr_reader :templates
  attr_reader :crm_config
  attr_reader :rsc_defaults
  attr_reader :op_defaults
  attr_reader :resource_count
  attr_reader :tickets
  attr_reader :tags
  attr_reader :resources_by_id
  attr_reader :booth
  attr_reader :constraints

  def persisted?
    true
  end

  def meta
    @meta ||= begin
      struct = {}

      @xml.root.attributes.each do |n, v|
        struct[n.underscore.to_sym] = Util.unstring(v, '')
      end unless @xml.nil?

      struct[:epoch] = epoch
      struct[:dc] = dc

      struct[:host] = Socket.gethostname

      struct[:version] = crm_config[:dc_version]
      struct[:stack] = crm_config[:cluster_infrastructure]

      struct[:status] = case
      when errors.empty?
        # TODO(must): Add stopped checks

        maintain = nodes.map do |node|
          node[:maintenance] || false
        end

        case
        when maintain.include?(true)
          :maintenance
        else
          :ok
        end
      when !@crm_config[:stonith_enabled]
        :nostonith
      else
        :errors
      end

      struct
    end
  end

  def live?
    id == 'live'
  end

  def sim?
    id != 'live'
  end

  def offline?
    meta[:status] == :offline
  end

  def not_a_node?
    return false unless offline?
    !File.exist?('/var/lib/pacemaker')
  end

  def node_state_of_resource(rsc)
    nodestate = {}
    rsc[:instances].each do |_, attrs|
      [:master, :slave, :started, :failed, :pending].each do |rstate|
        attrs[rstate].each do |n|
          nodestate[n[:node]] = rstate
        end if attrs[rstate]
      end
    end if rsc.key? :instances
    rsc[:children].each do |child|
      nodestate = nodestate.merge(node_state_of_resource(child))
    end if rsc.key? :children
    nodestate
  end

  def status(minimal = false)
    {
      meta: meta,
      errors: errors,
      booth: booth
    }.tap do |result|
      if minimal
        result[:resources] = {}
        result[:nodes] = {}
        result[:remote_nodes] = {}
        result[:tickets] = {}

        resources.each do |rsc|
          result[:resources][rsc[:id]] = node_state_of_resource(rsc)
        end

        current_nodes.each do |node|
          result[:nodes][node[:uname]] = node[:state]
          result[:remote_nodes][node[:uname]] = node[:state] if node[:remote]
        end

        current_tickets.each do |key, values|
          result[:tickets][key] = values[:state]
        end

      else
        result[:crm_config] = crm_config
        result[:rsc_defaults] = rsc_defaults
        result[:op_defaults] = op_defaults

        result[:resources] = resources
        result[:resources_by_id] = resources_by_id
        result[:nodes] = nodes
        result[:tickets] = tickets
        result[:tags] = tags
        result[:constraints] = constraints
      end
    end
  end

  def current_resources
    resources_by_id.select do |_, values|
      values[:instances]
    end
  end

  def current_nodes
    nodes
  end

  def current_tickets
    tickets
  end

  def current_tags
    tags
  end

  def current_constraints
    constraints
  end

  def primitives
    ret = []
    @resources.each do |r|
      if r.key? :children
        r[:children].each do |c|
          ret << c if c.key? :instances
        end
      elsif r.key? :instances
        ret << r
      end
    end
    ret
  end

  def find_node(node_id)
    fail(RecordNotFound, node_id) if @xml.nil?

    state = @nodes.select { |n| n[:id] == node_id || n[:uname] == node_id }
    fail(RecordNotFound, node_id) if state.blank?
    can_fence = @crm_config[:stonith_enabled]

    node = @xml.elements["cib/configuration/nodes/node[@uname=\"#{node_id}\"]"]
    if node
      Node.instantiate(node, state.first, can_fence)
    else
      node = @xml.elements["cib/configuration/nodes/node[@id=\"#{node_id}\"]"]
      if node
        Node.instantiate(node, state.first, can_fence)
      else
        fail RecordNotFound, node_id
      end
    end
  end

  def nodes_ordered
    ret = []
    return ret if @xml.nil?
    can_fence = @crm_config[:stonith_enabled]
    @xml.elements.each('cib/configuration/nodes/node') do |xml|
      node_id = xml.attributes['id']
      state = @nodes.select { |n| n[:id] == node_id }
      ret << Node.instantiate(xml, state[0], can_fence)
    end
    ret
  end

  def match(xpath)
    return [] if @xml.nil?
    REXML::XPath.match(@xml, xpath)
  end

  def first(xpath)
    return [] if @xml.nil?
    REXML::XPath.first(@xml, xpath)
  end

  protected

  def get_resource(elem, is_managed = true, clone_max = nil, is_ms = false)
    res = {
      id: elem.attributes['id'],
      object_type: elem.name,
      attributes: {},
      is_managed: is_managed,
      state: :unknown
    }
    @resources_by_id[elem.attributes['id']] = res
    elem.elements.each("meta_attributes/nvpair/") do |nv|
      res[:attributes][nv.attributes["name"]] = nv.attributes["value"]
    end
    if res[:attributes].key?("is-managed")
      res[:is_managed] = Util.unstring(res[:attributes]["is-managed"], true)
    end
    if res[:attributes].key?("maintenance")
      # A resource on maintenance is also flagged as unmanaged
      res[:is_managed] = false if Util.unstring(res[:attributes]["maintenance"], false)
    end
    case elem.name
    when 'primitive'
      res[:class]     = elem.attributes['class']
      res[:provider]  = elem.attributes['provider'] # This will be nil for LSB resources
      res[:type]      = elem.attributes['type']
      res[:template]  = elem.attributes['template']
      res[:instances] = {}
      # This is a bit of a hack to ensure we have a complete set of instances later
      res[:clone_max] = clone_max if clone_max
      # Likewise to s/started/slave/
      res[:is_ms]     = is_ms
    when 'group', 'clone', 'master'
      # For non-primitives we overload :type (it's not a primitive if
      # it has children, or, for that matter, if it has no class)
      res[:type]     = elem.name
      res[:children] = []
      if elem.name == 'clone' || elem.name == 'master'
        nvpair = elem.elements["meta_attributes/nvpair[@name='clone-max']"]
        clone_max = nvpair ? nvpair.attributes['value'].to_i : @nodes.length
      end
      if elem.elements['primitive']
        elem.elements.each('primitive') do |p|
          res[:children] << get_resource(p, res[:is_managed], clone_max, is_ms || elem.name == 'master')
        end
      elsif elem.elements['group']
        res[:children] << get_resource(elem.elements['group'], res[:is_managed], clone_max, is_ms || elem.name == 'master')
      else
        # This can't happen
        Rails.logger.error "Got #{elem.name} without 'primitive' or 'group' child"
      end
    else
      # This really can't happen
      Rails.logger.error "Unknown resource type: #{elem.name}"
    end
    res
  end

  # Hack to:
  # - inject additional instances for clones if there's no LRM state for them
  # - remove default instance for clones (shouldn't be there, but will be due
  #   to orphans if you create a clone from a running primitive or group).
  # - remove clone instances from primitives (shouldn't be there, but will be
  #   due to orphans if you un-clone a running cloned primitive or group)
  # - count total number of configured resource instances
  def fix_clone_instances(rsclist)
    rsclist.each do |res|
      if res[:clone_max]
        # There'll be a stale default instance lying around if the resource was
        # started before it was cloned (bnc#711180), so ditch it.  This is all
        # getting a bit convoluted - need to rethink...
        res[:instances].delete(:default)
        instance = 0
        while res[:instances].length < res[:clone_max]
          while res[:instances].key?(instance.to_s.to_sym)
            instance += 1
          end
          res[:instances][instance.to_s.to_sym] = {
            failed_ops: [],
            is_managed: res[:is_managed] && !@crm_config[:maintenance_mode]
          }
        end
        res[:instances].delete(:default) if res[:instances].key?(:default)
        # strip any instances outside 0..clone_max if they're not running (these
        # can be present if, e.g.: you have a clone running on all nodes, then
        # set clone-max < num_nodes, in which case there'll be stopped orphans).
        res[:instances].keys.select{|i| i.to_s.to_i >= res[:clone_max]}.each do |k|
          # safe to delete if the instance is present and its only state is stopped
          res[:instances].delete(k) if res[:instances][k].keys.length == 1 && res[:instances][k].key?(:stopped)
        end
        res.delete :clone_max
      else
        if res.key?(:instances)

          res[:instances].delete_if do |k, v|
            k != :default
          end
          # Inject a default instance if there's not one, as can be the case when
          # working with shadow CIBs.
          res[:instances][:default] = {
            failed_ops: [],
            is_managed: res[:is_managed] && !@crm_config[:maintenance_mode]
          } unless res[:instances].key?(:default)
        end
      end
      @resource_count += res[:instances].count if res[:instances]
      fix_clone_instances(res[:children]) if res[:children]
    end
  end

  # After all the instance states have been calculated, we
  # can calculate a total resource state
  def fix_resource_states(rsclist)
    prio = {
      unknown: 0,
      stopped: 1,
      started: 2,
      slave: 3,
      master: 4,
      pending: 5,
      failed: 6
    }
    rsclist.each do |resource|
      resource[:running_on] = {}
      resource[:state] ||= :stopped
      if resource.key? :instances
        resource[:state] = :stopped if resource[:state] == :unknown
        resource[:instances].each do |_, states|
          prio.keys.each do |rstate|
            if states.key? rstate
              p1 = prio[rstate]
              p2 = prio[resource[:state]]
              resource[:state] = rstate if p1 > p2

              unless [:started, :slave, :master].find_index(rstate).nil?
                states[rstate].each do |instance|
                  resource[:running_on][instance[:node]] = rstate
                end
              end
            end
          end
        end
      end

      if resource.key? :children
        fix_resource_states(resource[:children])
        resource[:children].each do |child|
          rstate = child[:state]
          resource[:state] = rstate if prio[rstate] > prio[resource[:state]]
          resource[:running_on].merge! child[:running_on]
        end
      end
    end
  end

  def inject_default_instance
    @resources_by_id.each do |k, _|
      @resources_by_id[k].delete :is_ms
      # Need to inject a default instance if we don't have any state
      # (e.g. during cluster bringup) else the panel renderer chokes.
      if @resources_by_id[k][:instances] && @resources_by_id[k][:instances].empty?
        # Always include empty failed_ops array (JS status updater relies on it)
        @resources_by_id[k][:instances][:default] = {
          failed_ops: [],
          is_managed: @resources_by_id[k][:is_managed] && !@crm_config[:maintenance_mode]
        }
      end
    end
  end

  # After all the resource states have been calculated, we
  # can calculate a total tag state
  def fix_tag_states
    prio = {
      unknown: 0,
      stopped: 1,
      started: 2,
      slave: 3,
      master: 4,
      pending: 5,
      failed: 6
    }
    @tags.each do |tag|
      sum_state = :unknown
      tag[:refs].each do |ref|
        tagged = @resources_by_id[ref]
        unless tagged.nil?
          rstate = tagged[:state]
          unless rstate.nil?
            if prio[rstate] > prio[sum_state]
              sum_state = rstate
            end
          end
        end
      end
      tag[:state] = sum_state
    end
  end

  def get_constraint(elem)
    objtype = {
      rsc_location: :location,
      rsc_colocation: :colocation,
      rsc_order: :order,
      rsc_ticket: :ticket
    }
    ret = {
      id: elem.attributes['id'],
      object_type: objtype[elem.name.to_sym] || elem.name,
      children: []
    }
    ["rsc", "with-rsc", "first", "then"].each do |attr|
      ret[:children] << elem.attributes[attr] unless elem.attributes[attr].nil?
    end
    ["score", "node", "resource-discovery", "ticket"].each do |attr|
      ret[attr.underscore.to_sym] = elem.attributes[attr] unless elem.attributes[attr].nil?
    end
    elem.elements.each("resource_set/resource_ref") do |ref|
      ret[:children] << ref.attributes['id']
    end
    ret
  end

  public

  def errors
    @errors ||= []
  end

  def error(msg, type = :danger, additions = {})
    additions.merge! msg: msg, type: type
    additions[type] = true

    errors.push additions
  end

  def initialize(id, user, use_file = false)
    Rails.logger.debug "Cib.initialize #{id}, #{user}, #{use_file}"

    if use_file
      cib_path = id
      # TODO(must): This is a bit rough
      cib_path.gsub!(/[^\w-]/, '')
      cib_path = "#{Rails.root}/test/cib/#{cib_path}.xml"
      raise ArgumentError, _('CIB file "%{path}" not found') % { path: cib_path } unless File.exist?(cib_path)
      @xml = REXML::Document.new(File.new(cib_path))
      #raise RuntimeError, _('Unable to parse CIB file "%{path}"') % {path: cib_path } unless @xml.root
      unless @xml.root
        error _('Unable to parse CIB file "%{path}"') % {path: cib_path }
        init_offline_cluster id, user, use_file
        return
      end
    else
      unless File.exists?('/usr/sbin/crm_mon')
        error _('Pacemaker does not appear to be installed (%{cmd} not found)') % {
          cmd: '/usr/sbin/crm_mon' }
        init_offline_cluster id, user, use_file
        return
      end
      unless File.executable?('/usr/sbin/crm_mon')
        error _('Unable to execute %{cmd}') % {cmd: '/usr/sbin/crm_mon' }
        init_offline_cluster id, user, use_file
        return
      end
      out, err, status = Util.run_as(user, 'cibadmin', '-Ql')
      case status.exitstatus
      when 0
        @xml = REXML::Document.new(out)
        unless @xml && @xml.root
          error _('Error invoking %{cmd}') % {cmd: '/usr/sbin/cibadmin -Ql' }
          init_offline_cluster id, user, use_file
          return
        end
      when 54, 13
        # 13 is cib_permission_denied (used to be 54, before pacemaker 1.1.8)
        error _('Permission denied for user %{user}') % {user: user}
        init_offline_cluster id, user, use_file
        return
      else
        error _('Error invoking %{cmd}: %{msg}') % {cmd: '/usr/sbin/cibadmin -Ql', msg: err }
        init_offline_cluster id, user, use_file
        return
      end
    end

    @id = id

    # Special-case defaults for properties we always want to see
    @crm_config = {
      cluster_infrastructure: _('Unknown'),
      dc_version: _('Unknown'),
      stonith_enabled: true,
      symmetric_cluster: true,
      no_quorum_policy: 'stop',
    }

    # Pull in everything else
    # TODO(should): This gloms together all cluster property sets; really
    # probably only want cib-bootstrap-options?
    @xml.elements.each('cib/configuration/crm_config//nvpair') do |p|
      @crm_config[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
    end

    @rsc_defaults = {}
    @xml.elements.each('cib/configuration/rsc_defaults//nvpair') do |p|
      @rsc_defaults[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
    end

    @op_defaults = {}
    @xml.elements.each('cib/configuration/op_defaults//nvpair') do |p|
      @op_defaults[p.attributes['name'].underscore.to_sym] = CibTools.get_xml_attr(p, 'value')
    end

    is_managed_default = true
    if @crm_config.key?(:is_managed_default) && !@crm_config[:is_managed_default]
      is_managed_default = false
    end

    @nodes = []
    @xml.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      node_id = n.attributes['id']
      state = :unclean
      standby = false
      maintenance = @crm_config[:maintenance_mode] ? true : false
      remote = n.attributes['type'] == 'remote'
      ns = @xml.elements["cib/status/node_state[@uname='#{uname}']"]
      if ns
        state = CibTools.determine_online_status(ns, crm_config[:stonith_enabled])
        selems = n.elements["instance_attributes/nvpair[@name='standby']"]
        # TODO(could): is the below actually a sane test?
        if selems && ['true', 'yes', '1', 'on'].include?(selems.attributes['value'])
          standby = true
        end
        m = n.elements["instance_attributes/nvpair[@name='maintenance']"]
        if m && ['true', 'yes', '1', 'on'].include?(m.attributes['value'])
          maintenance = true
        end
      else
        # If there's no node state at all, the node is unclean if fencing is enabled,
        # and offline if fencing is disabled.
        state = crm_config[:stonith_enabled] ? :unclean : :offline
      end
      if standby and state == :online
        state = :standby
      end

      # check stonith history
      if crm_config[:stonith_enabled]
        fence_history = %x[/usr/sbin/stonith_admin -H #{uname} 2>/dev/null].strip
      else
        fence_history = ""
      end

      @nodes << {
        name: uname || id,
        uname: uname,
        state: state,
        id: node_id,
        standby: standby,
        maintenance: maintenance,
        remote: remote,
        fence_history: fence_history
      }
      if state == :unclean
        error _('Node "%{node}" is UNCLEAN and needs to be fenced.') % { node: uname }
      end
    end

    # add remote nodes that may not exist in cib/configuration/nodes/node
    @xml.elements.each("cib/status/node_state[remote_node='true']") do |n|
      uname = n.attributes['uname']
      node_id = n.attributes['id']
      # To determine the state of remote nodes, we need to look at
      # the resource by the same name
      state = :unknown
      standby = false
      unless @nodes.any? { |nod| nod[:id] == node_id }
        @nodes << {
          uname: uname,
          state: state,
          id: node_id,
          standby: standby,
          maintenance: maintenance,
          remote: true
        }
      end
    end

    @resources = []
    @resources_by_id = {}
    @resource_count = 0
    # This gives only resources capable of being instantiated, and skips (e.g.) templates
    @xml.elements.each('cib/configuration/resources/*[self::primitive or self::group or self::clone or self::master]') do |r|
      @resources << get_resource(r, is_managed_default && !@crm_config[:maintenance_mode])
    end
    # Templates deliberately kept separate from resources, because
    # we need an easy way of listing them separately, and they don't
    # have state we care about.
    @templates = []
    @xml.elements.each('cib/configuration/resources/template') do |t|
      @templates << {
        id: t.attributes['id'],
        class: t.attributes['class'],
        provider: t.attributes['provider'],
        type: t.attributes['type']
      }
    end if Util.has_feature?(:rsc_template)

    # TODO(must): fix me
    @constraints = []
    @xml.elements.each('cib/configuration/constraints/*') do |c|
      @constraints << get_constraint(c)
    end

    @tags = []
    @xml.elements.each('cib/configuration/tags/tag') do |t|
      @tags << {
        id: t.attributes['id'],
        state: :unknown,
        object_type: :tag,
        is_managed: false,
        running_on: {},
        refs: t.elements.collect('obj_ref') { |ref| ref.attributes['id'] }
      }
    end

    # Iterate nodes in cib order here which makes the faked up clone & ms instance
    # IDs be in the same order as pacemaker
    for node in @nodes
      @xml.elements.each("cib/status/node_state[@uname='#{node[:uname]}']/lrm/lrm_resources/lrm_resource") do |lrm_resource|
        rsc_id = lrm_resource.attributes['id']
        # logic derived somewhat from pacemaker/lib/pengine/unpack.c:unpack_rsc_op()
        state = :unknown
        substate = nil
        failed_ops = []
        ops = []
        lrm_resource.elements.each('lrm_rsc_op') do |op|
          ops << op
        end
        ops.sort{|a,b|
          if a.attributes['call-id'].to_i != -1 && b.attributes['call-id'].to_i != -1
            # Normal case, neither op is pending, call-id wins
            a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
          elsif a.attributes['operation'].starts_with?('migrate_') || b.attributes['operation'].starts_with?('migrate_')
            # Special case for pending migrate ops, beacuse stale ops hang around
            # in the CIB (see lf#2481).  There's a couple of things to do here:
            a_key = a.attributes['transition-key'].split(':')
            b_key = b.attributes['transition-key'].split(':')
            if a.attributes['transition-key'] == b.attributes['transition-key']
              # 1) if the transition keys match, newer call-id wins (ensures bogus
              # pending ops lose to immediately subsequent start/stop).
              a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
            elsif a_key[3] == b_key[3]
              # 2) if the transition keys don't match but the transitioner UUIDs
              # *do* match, the migrate is either old (predating a start/stop that
              # occurred after a migrate's regular start/stop), or new (the current
              # pending op), in which case we assume the larger graph number is the
              # most recent op (this will break if uint64_t ever wraps).
              a_key[1].to_i <=> b_key[1].to_i
            else
              # If the transitioner UUIDs *don't* match (different instances
              # of crmd), we make the pending op most recent (reverse sort
              # call id), because experiment seems to indicate this is the
              # least-worst choice.  Pending migrate ops for a node evaporate
              # if Pacemaker is stopped on that node, so after a UUID change,
              # there should be at most one outstanding pending migrate op
              # that doesn't hit one of the other rules above - if this is
              # the case, this pending migrate op is what's happening right
              # *now*
              b.attributes['call-id'].to_i <=> a.attributes['call-id'].to_i
            end
          elsif a.attributes['operation'] == b.attributes['operation'] &&
                a.attributes['transition-key'] == b.attributes['transition-key']
            # Same operation, same transition key, and one op is allegedly pending.
            # This is a lie (see bnc#879034), so make newer call-id win hand have
            # bogus pending op lose (similar to above special case for migrate ops)
            a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
          elsif a.attributes['call-id'].to_i == -1
            1                                         # make pending start/stop op most recent
          elsif b.attributes['call-id'].to_i == -1
            -1                                        # likewise
          else
            Rails.logger.error "Inexplicable op sort error (this can't happen)"
            a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
          end
        }.each do |op|
          operation = op.attributes['operation']
          rc_code = op.attributes['rc-code'].to_i
          # Cope with missing transition key (e.g.: in multi1.xml CIB from pengine/test10)
          # TODO(should): Can we handle this better?  When is it valid for the transition
          # key to not be there?
          expected = rc_code
          graph_number = nil
          if op.attributes.key?('transition-key')
            k = op.attributes['transition-key'].split(':')
            graph_number = k[1].to_i
            expected = k[2].to_i
          end

          exit_reason = op.attributes.key?('exit-reason') ? op.attributes['exit-reason'] : ''

          # skip notifies, deletes, cancels
          next if operation == 'notify' || operation == 'delete' || operation == 'cancel'

          # skip allegedly pending "last_failure" ops (hack to fix bnc#706755)
          # TODO(should): see if we can remove this in future
          next if op.attributes.key?('id') &&
            op.attributes['id'].end_with?("_last_failure_0") && op.attributes['call-id'].to_i == -1

          if op.attributes['call-id'].to_i == -1
            # Don't do any further processing for pending ops, but only set
            # resource state to "pending" if it's not a pending monitor
            # TODO(should): Look at doing this by "whitelist"? i.e. explicitly
            # notice pending start, stop, promote, demote, migrate_*..?
            # This would allow us to say "Staring", "Stopping", etc. in the UI.
            state = :pending if operation != "monitor"
            case operation
            when "start"
              substate = :starting
            when "stop"
              substate = :stopping
            when "promote"
              substate = :promoting
            when "demote"
              substate = :demoting
            when /^migrate/
              substate = :migrating
            end
            next
          end

          is_probe = operation == 'monitor' && op.attributes['interval'].to_i == 0
          # Report failure if rc_code != expected, unless it's a probe,
          # in which case we only report failure when rc_code is not
          # 0 (running), 7 (not running) or 8 (running master), i.e. is
          # some error value.
          if rc_code != expected && (!is_probe || (rc_code != 0 && rc_code != 7 && rc_code != 8))

            # if on-fail == ignore for this op, pretend it succeeded for the purposes of state calculation
            ignore_failure = false
            @xml.elements.each("cib/configuration//primitive[@id='#{rsc_id.split(":")[0]}']/operations/op[@name='#{operation}']") do |e|
              next unless e.attributes["on-fail"] && e.attributes["on-fail"] == "ignore"
              # TODO(must): Verify interval is correct
              ignore_failure = true
            end

            # Want time span of failed op to link to history explorer.
            # Failed ops seem to only have last-rc-change, but in case this is
            # an incorrect assumption we'll take the earlier of last-run and
            # last-rc-change if both exist, then subtract exec-time and queue-time

            times = []
            times << op.attributes['last-rc-change'].to_i if op.attributes['last-rc-change']
            times << op.attributes['last-run'].to_i if op.attributes['last-run']
            fail_start = fail_end = times.min
            if (fail_start)
              fail_start -= (op.attributes['exec-time'].to_i / 1000) if op.attributes['exec-time']
              fail_start -= (op.attributes['queue-time'].to_i / 1000) if op.attributes['queue-time']

              # Now extend by (a somewhat arbitrary) ten minutes on either side
              fail_start -= 600
              fail_end += 600

              fail_start = Time.at(fail_start).strftime("%Y-%m-%d %H:%M")
              fail_end = Time.at(fail_end).strftime("%Y-%m-%d %H:%M")
            end

            failed_ops << {
              node: node[:uname],
              call_id: op.attributes['call-id'],
              op: operation,
              rc_code: rc_code,
              exit_reason: exit_reason,
              fail_start: fail_start,
              fail_end: fail_end
            }
            error(_('%{fail_start}: Operation %{op} failed for resource %{resource} on node %{node}: call-id=%{call_id}, rc-code=%{rc_mapping} (%{rc_code}), exit-reason=%{exit_reason}') % {
                    node: node[:uname],
                    resource: "<strong>#{rsc_id}</strong>".html_safe,
                    call_id: op.attributes['call-id'],
                    op: "<strong>#{operation}</strong>".html_safe,
                    rc_mapping: CibTools.rc_desc(rc_code),
                    rc_code: rc_code,
                    exit_reason: exit_reason,
                    fail_start: fail_start || '0000-00-00 00:00'
                  })

            if ignore_failure
              failed_ops[-1][:ignored] = true
              rc_code = expected
            else
              if operation == "stop"
                # We have a failed stop, the resource is failed (bnc#879034)
                state = :failed
                # Also, the node is thus unclean if STONITH is enabled.
                node[:state] = :unclean if @crm_config[:stonith_enabled]
              end
            end
          end

          # TODO(should): evil magic numbers!
          # The operation and RC code tells us the state of the resource on this node
          # when rc=0, anything other than a stop means we're running
          # (might be slave after a demote)
          # TODO(must): verify this demote business
          case rc_code
          when 7
            state = :stopped
          when 8
            state = :master
          when 0
            if operation == 'stop' || operation == 'migrate_to'
              state = :stopped
            elsif operation == 'promote'
              state = :master
            else
              state = :started
            end
          end
        end


        # TODO(should): want some sort of assert "status != :unknown" here
        # Now we've got the status on this node, let's stash it away
        (rsc_id, instance) = rsc_id.split(':')
        # Need check for :instances in case an orphaned resource has same id
        # as a currently extant clone parent (bnc#834198)
        if @resources_by_id[rsc_id] && @resources_by_id[rsc_id][:instances]
          update_resource_state @resources_by_id[rsc_id], node, instance, state, substate, failed_ops
          # NOTE: Do *not* add any more keys here without adjusting the renamer above
        else
          # It's an orphan
          Rails.logger.debug "Ignoring orphaned resource #{rsc_id + (instance ? ':' + instance : '')}"
        end
      end
    end

    fix_clone_instances @resources
    inject_default_instance
    fix_resource_states @resources
    fix_tag_states

    # Now we can patch up the state of remote nodes
    @nodes.each do |n|
      if n[:remote] && n[:state] != :unclean
        rsc = @resources_by_id[n[:id]]
        if rsc && [:master, :slave, :started].include?(rsc[:state])
          n[:state] = :online
        elsif rsc && [:failed, :pending].include?(rsc[:state])
          n[:state] = :unclean
        else
          n[:state] = :offline
        end
      end
    end

    # Now we can sort the node array
    @nodes.sort!{|a,b| a[:uname].natcmp(b[:uname], true)}

    # TODO(should): Can we just use cib attribute dc-uuid?  Or is that not viable
    # during cluster bringup, given we're using cibadmin -l?
    # Note that crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    @dc = %x[/usr/sbin/crmadmin -t 100 -D 2>/dev/null].strip
    s = @dc.rindex(' ')
    @dc.slice!(0, s + 1) if s
    @dc = _('Unknown') if @dc.empty?

    @epoch = CibTools.epoch_string @xml.root

    # Tickets will always have a granted property (boolean).  They may also
    # have a last-granted timestamp too, but this will only be present if a
    # ticket has ever been granted - it won't be there for tickets we only
    # pick up from rsc_ticket constraints.
    @tickets = {}
    @xml.elements.each("cib/status/tickets/ticket_state") do |ts|
      t = ts.attributes["id"]
      ticket = {
        id: t,
        state: :revoked,
        granted: Util.unstring(ts.attributes["granted"], false),
        standby: Util.unstring(ts.attributes["standby"], false),
        last_granted: ts.attributes["last-granted"]
      }
      ticket[:state] = :granted if ticket[:granted]
      ticket[:state] = :standby if ticket[:standby]
      @tickets[t] = ticket
    end

    # Pick up tickets defined in rsc_ticket constraints
    @xml.elements.each("cib/configuration/constraints/rsc_ticket") do |rt|
      t = rt.attributes["ticket"]
      if @tickets[t]
        @tickets[t][:constraints] ||= []
        @tickets[t][:constraints].push rt.attributes["id"]
      else
        @tickets[t] = {
          id: t,
          state: :revoked,
          granted: false,
          standby: false,
          last_granted: nil,
          constraints: [rt.attributes["id"]]
        }
      end
    end

    @booth = {sites: [], arbitrators: [], tickets: [], me: nil}
    # Figure out if we're in a geo cluster
    File.readlines("/etc/booth/booth.conf").each do |line|
      m = line.match(/^\s*(site|arbitrator|ticket)\s*=(.+)/)
      next unless m
      v = Util.strip_quotes(m[2].strip)
      next unless v
      # This split is to tear off ticket expiry times if present
      # (although they should no longer be set like this since the
      # config format changed, but still doesn't hurt)
      @booth["#{m[1]}s".to_sym] << v.split(";")[0]
    end if File.exists?("/etc/booth/booth.conf")

    # Figure out if we're a site in a geo cluster (based on existence of
    # IPaddr2 resource with same IP as a site in booth.conf)
    if !@booth[:sites].empty?
      @booth[:sites].sort!
      @xml.elements.each("cib/configuration//primitive[@type='IPaddr2']/instance_attributes/nvpair[@name='ip']") do |elem|
        ip = CibTools.get_xml_attr(elem, "value")
        next unless @booth[:sites].include?(ip)
        if !@booth[:me]
          @booth[:me] = ip
        else
          Rails.logger.warn "Multiple booth sites in CIB (first match was #{@booth[:me]}, also found #{ip})"
        end
      end
    end

    if @booth[:me]
      # Pick up tickets defined in booth config
      @booth[:tickets].each do |t|
        @tickets[t] = {
          id: t,
          state: :revoked,
          granted: false,
          standby: false,
          last_granted: nil
        } unless @tickets[t]
      end

      # try to get a bit more ticket info
      %x[/usr/sbin/booth client list 2>/dev/null].split("\n").each do |line|
        t = nil
        line.split(",").each do |pair|
          m = pair.match(/(ticket):\s*(.*)/)
          t = m[2] if m
        end
        line.split(",").each do |pair|
          m = pair.match(/(leader|expires|commit):\s*(.*)/)
          @tickets[t][m[1].to_sym] = m[2] if m
        end if t && @tickets[t]
      end
    end

    # set ticket state correctly
    @tickets.each do |_, ticket|
      if ticket[:state] == :revoked && (ticket[:leader] && ticket[:leader].downcase != "none")
        ticket[:state] = :elsewhere
      end
    end

    error(
      _("STONITH is disabled. For normal cluster operation, STONITH is required."),
      :warning,
      link: edit_cib_crm_config_path(cib_id: @id)
    ) unless @crm_config[:stonith_enabled]
  end

  def init_offline_cluster(id, user, use_file)
    @id = id

    @meta = {
      epoch: "",
      dc: "",
      host: "",
      version: "",
      stack: "",
      status: :offline
    }

    @crm_config = {
      cluster_infrastructure: _('Unknown'),
      dc_version: _('Unknown')
    }
    @nodes = []
    @resources = []
    @resources_by_id = {}
    @resource_count = 0
    @templates = []
    @constraints = []
    @tags = []
    @tickets = []
  end

  def update_resource_state(resource, node, instance, state, substate, failed_ops)
    # m/s slave state hack (*sigh*)
    state = :slave if resource[:is_ms] && state == :started
    instances = resource[:instances]

    if !instance && resource.key?(:clone_max)
      # Pacemaker commit 427c7fe6ea94a566aaa714daf8d214290632f837 removed
      # instance numbers from anonymous clones.  Too much of hawk wants
      # these, so we fake them back in if they're not present, by getting
      # the current maximum instance number (if present) and incrementing
      # it.
      # Note: instance at this point is a string because that's what
      # everything else expects
      instance = instances.select {|k,v| Util.numeric?(k)}.map {|k,v| k.to_i}.max
      if instance.nil?
        instance = "0"
      else
        instance = (instance + 1).to_s
      end
    end

    if instance && state != :stopped && state != :unknown
      # For clones, it's possible we need to rename an instance if
      # there's already a running instance with this ID.  An instance
      # is running (or possibly failed, as after a failed stop) iff:
      # - @resources_by_id[id][:instances][instance] exists, and,
      # - there are state keys other than :stopped, :unknown, :is_managed or :failed_ops present
      alt_i = instance
      while instances[alt_i] &&
            instances[alt_i].count{|k,v| (k != :stopped && k != :unknown && k != :is_managed && k != :failed_ops)} > 0
        alt_i = (alt_i.to_i + 1).to_s
      end
      if alt_i != instance
        rsc_id = resource[:id]
        Rails.logger.debug "Internally renamed #{rsc_id}:#{instance} to #{rsc_id}:#{alt_i} on #{node[:uname]}"
        instance = alt_i
      end
    else
      # instance will be nil here for regular primitives
      instance = :default
    end

    instance = instance.to_sym

    # Carry is_managed into the instance itself (needed so we can correctly
    # display unmanaged clone instances if a single node is on maintenance,
    # but only do this on first initialization else state may get screwed
    # up later
    instances[instance] = {
      is_managed: resource[:is_managed] && !@crm_config[:maintenance_mode]
    } unless instances[instance]
    instances[instance][state] ||= []
    n = { node: node[:uname] }
    n[:substate] = substate if substate
    instances[instance][state] << n
    instances[instance][:failed_ops] = [] unless instances[instance][:failed_ops]
    instances[instance][:failed_ops].concat failed_ops
    if state != :unknown && state != :stopped && node[:maintenance]
      # mark it unmanaged if the node is on maintenance and it's actually
      # running here (don't mark it unmanaged if it's stopped on this
      # node - it might be running on another node)
      instances[instance][:is_managed] = false
    end

    resource
  end
end
