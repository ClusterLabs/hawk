require 'util'
require 'rexml/document' unless defined? REXML::Document

class CibController < ApplicationController
  before_filter :login_required

  protected

  # Gives back a string, boolean if value is "true" or "false",
  # or nil if attribute doesn't exist and there's no default
  # (roughly equivalent to crm_element_value() in Pacemaker)
  # TODO(should): be nice to get integers auto-converted too
  def get_xml_attr(elem, name, default = nil)
    v = elem.attributes[name] || default
    ['true', 'false'].include?(v.class == String ? v.downcase : v) ? v.downcase == 'true' : v
  end

  def get_property(property, default = nil)
    # TODO(could): theoretically this xpath is a bit loose.
    e = @cib.elements["//nvpair[@name='#{property}']"]
    e ? get_xml_attr(e, 'value', default) : default
  end

  def get_resource(elem, clone_max = nil, is_ms = false)
    res = {
      :id => elem.attributes['id']
    }
    @resources_by_id[elem.attributes['id']] = res
    case elem.name
    when 'primitive'
      res[:class]     = elem.attributes['class']
      res[:provider]  = elem.attributes['provider'] # This will be nil for LSB resources
      res[:type]      = elem.attributes['type']
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
          res[:children] << get_resource(p, clone_max, is_ms || elem.name == 'master')
        end
      elsif elem.elements['group']
        res[:children] << get_resource(elem.elements['group'], clone_max, is_ms || elem.name == 'master')
      else
        # This can't happen
        logger.error "Got #{elem.name} without 'primitive' or 'group' child"
      end
    else
      # This can't happen
        logger.error "Unknown resource type: #{elem.name}"
    end
    res
  end

  # Hack to inject additional instances for clones if there's no LRM state for them
  def inject_stopped_clone_instances(resources)
    for res in resources
      if res[:clone_max]
        instance = 0
        while res[:instances].length < res[:clone_max]
          while res[:instances].has_key?(instance.to_s)
            instance += 1
          end
          res[:instances][instance.to_s] = {}
        end
        res.delete :clone_max
      end
      inject_stopped_clone_instances(res[:children]) if res[:children]
    end
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_fencing()
  # ns is node_state element from CIB
  def determine_online_status_fencing(ns)
    ha_state    = get_xml_attr(ns, 'ha', 'dead')
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = :unclean
    if in_ccm && ha_state == 'active' && crm_state == 'online'
      case join_state
      when 'member'         # rock 'n' roll (online)
        state = :online
      when exp_state        # coming up (!online)
        state = :offline
      when 'pending'        # technically online, but not ready to run resources
        state = :pending    # (online + pending + standby)
      when 'banned'         # not allowed to be part of the cluster
        state = :standby    # (online + pending + standby)
      else                  # unexpectedly down (unclean)
        state = :unclean
      end
    elsif !in_ccm && ha_state =='dead' && crm_state == 'offline' && !expected_up
      state = :offline      # not online, but cleanly
    elsif expected_up
      state = :unclean      # expected to be up, mark it unclean
    else
      state = :offline      # offline
    end
    return state
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_no_fencing()
  # ns is node_state element from CIB
  # TODO(could): can we consolidate this with determine_online_status_fencing?
  def determine_online_status_no_fencing(ns)
    ha_state    = get_xml_attr(ns, 'ha', 'dead')
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = :unclean
    if !in_ccm || ha_state == 'dead'
      state = :offline
    elsif crm_state == 'online'
      if join_state == 'member'
        state = :online
      else
        # not ready yet (should this break down to pending/banned like
        # determine_online_status_fencing?  It doesn't in unpack.c...)
        state = :offline
      end
    elsif !expected_up
      state = :offline
    else
      state = :unclean
    end
    return state
  end

  public

  def initialize
    @errors = []

    # TODO(should): Need more deps than this (see crm)
    if File.exists?('/usr/sbin/crm_mon')
      if File.executable?('/usr/sbin/crm_mon')
        crm_status = %x[/usr/sbin/crm_mon -s 2>&1].chomp
        # TODO(should): this is dubious (WAR: crm_mon -s giving "status: 1, output was: Warning:offline node: hex-14")
        if $?.exitstatus == 10 || $?.exitstatus == 11
          @errors << _('%{cmd} failed (status: %{status}, output was: %{output})') %
                        {:cmd    => '/usr/sbin/crm_mon',
                         :status => $?.exitstatus,
                         :output => crm_status }
        end
      else
        @errors << _('Unable to execute %{cmd}') % {:cmd => '/usr/sbin/crm_mon' }
      end
    else
      @errors << _('Pacemaker does not appear to be installed (%{cmd} not found)') %
                    {:cmd => '/usr/sbin/crm_mon' }
    end
  end

  def index
    render :json => [ 'live' ]
  end

  def create
    head :forbidden
  end

  def new
    head :forbidden
  end

  def edit
    head :forbidden
  end

  def show
    # Only provide the live CIB and static test files (no shadow functionality yet)
    if params[:id] == 'live'
      stdin, stdout, stderr = Util.run_as(current_user, '/usr/sbin/cibadmin', '-Ql')
      case $?.exitstatus
      when 0
        @cib = REXML::Document.new(stdout.read())
        # If this failed, there'll be no root element
        unless @cib.root
          # TODO(should): clean up this error (not enough information)
          @errors << _('Error invoking %{cmd}') % {:cmd => '/usr/sbin/cibadmin -Ql' } if @errors.empty?
          render :status => 500, :json => { :errors => @errors }
          return
        end
        # Otherwise everything is fine, and we carry on
      when 54
        # 54 is cib_permission_denied
        @errors << _('Permission denied for user %{user}') % {:user => current_user}
        render :status => :forbidden, :json => { :errors => @errors }
        return
      else
        @errors << _('Error invoking %{cmd}: %{msg}') % {:cmd => '/usr/sbin/cibadmin -Ql', :msg => stderr.read() }
        render :status => 500, :json => { :errors => @errors }
        return
      end
    elsif params[:debug] == 'file'
      cib_path = params[:id]
      # TODO(must): This is a bit rough
      cib_path.gsub! /[^\w-]/, ''
      cib_path = "#{RAILS_ROOT}/test/cib/#{cib_path}.xml"
      unless File.exist?(cib_path)
        @errors << _('CIB file "%{path}" not found') % {:path => cib_path }
        render :json => { :errors => @errors }
        return
      end
      @cib = REXML::Document.new(File.new(cib_path))
      unless @cib.root
        # TODO(should): clean up this error (not enough information)
        @errors << _('Unable to parse CIB file "%{path}"') % {:path => cib_path }
        render :json => { :errors => @errors }
        return
      end
    else
      head :not_found
      return
    end

    # Special-case properties we always want to see
    crm_config = {
      :cluster_infrastructure       => get_property('cluster-infrastructure') || _('Unknown'),
      :dc_version                   => get_property('dc-version') || _('Unknown'),
      :default_resource_stickiness  => get_property('default-resource-stickiness', 0), # TODO(could): is this documented?
      :stonith_enabled              => get_property('stonith-enabled', true),
      :symmetric_cluster            => get_property('symmetric-cluster', true),
      :no_quorum_policy             => get_property('no-quorum-policy', 'stop'),
    }

    # Pull in everything else
    # TODO(should): This gloms together all cluster property sets; really
    # probably only want cib-bootstrap-options?
    @cib.elements.each('cib/configuration/crm_config//nvpair') do |p|
      sym = p.attributes['name'].tr('-', '_').to_sym
      next if crm_config[sym]
      crm_config[sym] = get_xml_attr(p, 'value')
    end

    @nodes = []
    @cib.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      state = :unclean
      ns = @cib.elements["cib/status/node_state[@uname='#{uname}']"]
      if ns
        state = crm_config[:stonith_enabled] ? determine_online_status_fencing(ns) : determine_online_status_no_fencing(ns)
        if state == :online
          standby = n.elements["instance_attributes/nvpair[@name='standby']"]
          # TODO(could): is the below actually a sane test?
          if standby && ['true', 'yes', '1', 'on'].include?(standby.attributes['value'])
            state = :standby
          end
        end
      end
      @nodes << {
        :uname => uname,
        :state => state
      }
    end
    @nodes.sort!{|a,b| a[:uname].natcmp(b[:uname], true)}

    @resources = []
    @resources_by_id = {}
    @cib.elements.each('cib/configuration/resources/*') do |r|
      @resources << get_resource(r)
    end

    for node in @nodes
      @cib.elements.each("cib/status/node_state[@uname='#{node[:uname]}']/lrm/lrm_resources/lrm_resource") do |lrm_resource|
        id = lrm_resource.attributes['id']
        # logic derived somewhat from pacemaker/lib/pengine/unpack.c:unpack_rsc_op()
        state = :unknown
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
          elsif a.attributes['call-id'].to_i == -1
            1                                         # make pending start/stop op most recent
          elsif b.attributes['call-id'].to_i == -1
            -1                                        # likewise
          else
            logger.error "Inexplicable op sort error (this can't happen)"
            a.attributes['call-id'].to_i <=> b.attributes['call-id'].to_i
          end
        }.each do |op|
          operation = op.attributes['operation']
          rc_code = op.attributes['rc-code'].to_i
          expected = op.attributes['transition-key'].split(':')[2].to_i

          is_probe = operation == 'monitor' && op.attributes['interval'].to_i == 0

          # skip notifies
          next if operation == 'notify'

          if op.attributes['call-id'].to_i == -1
            state = :pending
            next
          end

          # TODO(should): evil magic numbers!
          case rc_code
          when 7
            # not running on this node
            state = :stopped
          when 8
            # master on this node
            state = :master
          when 0
            # ok
            if operation == 'stop' || operation == 'migrate_to'
              state = :stopped
            elsif operation == 'promote'
              state = :master
            else
              # anything other than a stop means we're running (although might be
              # slave after a demote)
              # TODO(must): verify this demote business
              state = :started
            end
          end
          if !is_probe && rc_code != expected
            # busted somehow
            @errors << _('Failed op: node=%{node}, resource=%{resource}, call-id=%{call_id}, operation=%{op}, rc-code=%{rc_code}') %
              { :node => node[:uname], :resource => id, :call_id => op.attributes['call-id'], :op => operation, :rc_code => rc_code }
          end
        end

        # TODO(should): want some sort of assert "status != :unknown" here

        # Now we've got the status on this node, let's stash it away
        (id, instance) = id.split(':')
        if @resources_by_id[id]
          # m/s slave state hack (*sigh*)
          state = :slave if @resources_by_id[id][:is_ms] && state == :started
          # instance will be nil here for regular primitives
          instance = :default unless instance
          @resources_by_id[id][:instances][instance] = {} unless @resources_by_id[id][:instances][instance]
          @resources_by_id[id][:instances][instance][state] = [] unless @resources_by_id[id][:instances][instance][state]
          @resources_by_id[id][:instances][instance][state] << node[:uname]
        else
          # It's an orphan
          # TODO(should): display this somewhere? (at least log it during testing)
        end
      end
    end

    inject_stopped_clone_instances @resources

    # More hack
    @resources_by_id.each do |k,v|
      @resources_by_id[k].delete :is_ms
      # Need to inject a default instance if we don't have any state
      # (e.g. during cluster bringup) else the panel renderer chokes.
      @resources_by_id[k][:instances][:default] = {} if @resources_by_id[k][:instances] && @resources_by_id[k][:instances].empty?
    end

    # TODO(should): Can we just use cib attribute dc-uuid?  Or is that not viable
    # during cluster bringup, given we're using cibadmin -l?
    # Note that crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    dc = %x[/usr/sbin/crmadmin -t 100 -D 2>/dev/null].strip
    s = dc.rindex(' ')
    dc.slice!(0, s + 1) if s
    dc = _('Unknown') if dc.empty?

    # This blob is remarkably like the CIB, but staus is consolidated into the
    # main sections (nodes, resources) rather than being kept separate.
    render :json => {
      :meta => {
        :epoch  => "#{get_xml_attr(@cib.root, 'admin_epoch')}:#{get_xml_attr(@cib.root, 'epoch')}:#{get_xml_attr(@cib.root, 'num_updates')}",
        :dc     => dc
      },
      :errors => @errors,
      :crm_config => crm_config,
      :nodes => @nodes,
      :resources => @resources
      # also constraints, op_defaults, rsc_defaults, ...
    }
  end

  def update
    head :forbidden
  end

  def destroy
    head :forbidden
  end
end
