require 'natcmp'

class MainController < ApplicationController
  #before_filter :ensure_login

  # TODO: all this private stuff really belongs elsewhere
  # (models for cluster, nodes, resources anybody?)
  private

  # Gives back a string, boolean if value is "true" or "false",
  # or nil if attribute doesn't exist and there's no default
  # (roughly equivalent to crm_element_value() in Pacemaker)
  # TODO: be nice to get integers auto-converted too
  def get_xml_attr(elem, name, default = nil)
    v = elem.attributes[name] || default
    ['true', 'false'].include?(v.class == String ? v.downcase : v) ? v.downcase == 'true' : v
  end
  
  def get_property(property, default = nil)
    # TODO: theoretically this xpath is a bit loose.
    e = @cib.elements["//nvpair[@name='#{property}']"]
    e ? get_xml_attr(e, 'value', default) : default
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_fencing()
  # TODO: constants for states? (dead, active, etc.)
  # ns is node_state element from CIB
  def determine_online_status_fencing(ns)
    ha_state    = get_xml_attr(ns, 'ha', 'dead')
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = 'unclean'
    if in_ccm && ha_state == 'active' && crm_state == 'online'
      case join_state
      when 'member'         # rock 'n' roll (online)
        state = 'online'
      when exp_state        # coming up (!online)
        state = 'offline'
      when 'pending'        # technically online, but not ready to run resources
        state = 'pending'   # (online + pending + standby)
      when 'banned'         # not allowed to be part of the cluster
        state = 'standby'   # (online + pending + standby)
      else                  # unexpectedly down (unclean)
        state = 'unclean'
      end
    elsif !in_ccm && ha_state =='dead' && crm_state == 'offline' && !expected_up
      state = 'offline'     # not online, but cleanly
    elsif expected_up
      state = 'unclean'     # expected to be up, mark it unclean
    else
      state = 'offline'     # offline
    end
    return state
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_no_fencing()
  # TODO: constants for states? (dead, active, etc.)
  # ns is node_state element from CIB
  # TODO: can we consolidate this with determine_online_status_fencing?
  def determine_online_status_no_fencing(ns)
    ha_state    = get_xml_attr(ns, 'ha', 'dead')
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = 'unclean'
    if !in_ccm || ha_state == 'dead'
      state = 'offline'
    elsif crm_state == 'online'
      if join_state == 'member'
        state = 'online'
      else
        # not ready yet (should this break down to pending/banned like
        # determine_online_status_fencing?  It doesn't in unpack.c...)
        state = 'offline'
      end
    elsif !expected_up
      state = 'offline'
    else
      state = 'unclean'
    end
    return state
  end

  def get_cluster_status
    # TODO: error check this
    @cib = REXML::Document.new(%x[/usr/sbin/cibadmin -Ql])

    @summary[:stack]    = get_property('cluster-infrastructure')
    @summary[:version]  = get_property('dc-version')
    # trim version back to 12 chars (same length hg usually shows),
    # enough to know what's going on, and less screen real-estate
    ver_trimmed = @summary[:version].match(/.*-[a-f0-9]{12}/) if @summary[:version]
    @summary[:version]  = ver_trimmed[0] if ver_trimmed
    # crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    @summary[:dc]       = %x[/usr/sbin/crmadmin -t 100 -D 2>/dev/null].strip
    s = @summary[:dc].rindex(' ')
    @summary[:dc].slice!(0, s + 1) if s
    @summary[:dc]       = _('unknown') if @summary[:dc].empty?
    # default values per pacemaker 1.0 docs
    @summary[:default_resource_stickiness] = get_property('default-resource-stickiness', '0') # TODO: is this documented?
    @summary[:stonith_enabled]             = get_property('stonith-enabled', 'true') ? _('Enabled') : _('Disabled')
    @summary[:symmetric_cluster]           = get_property('symmetric-cluster', 'true') ? _('Symmetric') : _('Asymmetric')
    @summary[:no_quorum_policy]            = get_property('no-quorum-policy', 'stop')

    # See unpack_nodes in pengine.c for cleanliness
    # - if "startup-fencing" is false, unseen nodes are not unclean (dangerous)
    # - all nodes are unclean until we've seen their status
    # Possible node states (per print_status in crm_mon.c):
    #  - UNCLEAN (online)       (unclean && online)
    #  - UNCLEAN (pending)      (unclean && pending)
    #  - UNCLEAN (offline)      (unclean && none of the above)    
    #  - pending                (pending)
    #  - standby (on-fail)      (standby_onfail && online)
    #  - standby                (standby && online)
    #  - OFFLINE (standby)      (standby && !online)
    #  - online                 (online)
    #  - OFFLINE                (!online)
    # node_state attributes work as follows when *setting* state
    # with crm shell
    #  - crmd="online" expected="member" join="member"  (online)
    #  - crmd="offline" expected=""                     (offline)
    #  - crmd="offline" expected="member"               (unclean)
    #

    # hash, to sort by name
    nodes = {}

    @expand_nodes = false
    # Have to use cib/configuration/nodes/node as authoritative source,
    # because cib/status/node_state doesn't exist yet if cluster is
    # coming online.
    @cib.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      state = 'unclean'
      ns = @cib.elements["cib/status/node_state[@uname='#{uname}']"]
      if ns
        state = @stonith == 'true' ? determine_online_status_fencing(ns) : determine_online_status_no_fencing(ns)
        # figure out standby (god, what a mess)
        if state == 'online'
          n.elements.each('instance_attributes') do |ia|
            ia.elements.each('nvpair') do |p|
              if p.attributes['name'] == 'standby' &&
                 ['true', 'yes', '1', 'on'].include?(p.attributes['value'])
                # TODO: is the above actually a sane test?
                state = 'standby'
              end
            end
          end
        end
      end
      nodes[uname] = {
        :uname => uname,
        :state => state
      }
      # if anything is not online, expand by default
      @expand_nodes = true if state != 'online'
    end

    # sorted node list to array
    nodes.sort{|a,b| a[0].natcmp(b[0], true)}.each do |uname,node|
      @nodes << {
        :uname  => node[:uname],              # needed for resource status, not used by renderer
        :id     => "node-#{node[:uname]}",
        :class  => "node ns-#{node[:state]}",
        # TODO: localize?  HTML-safe?
        :label  => "#{node[:uname]}: #{node[:state]}"
      }
    end

    @expand_resources = false

    # States are:
    #  - Unknown
    #  - Stopped
    #  - Started
    #  - Slave
    #  - Master
    # State is determined by looking at ops for that resource, sorted
    # in reverse chronological order by call-id
    # possible operations are:
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_DELETE		"delete"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_CANCEL		"cancel"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_MIGRATE		"migrate_to"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_MIGRATED	"migrate_from"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_START		  "start"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_STARTED		"running"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_STOP		  "stop"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_STOPPED		"stopped"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_PROMOTE		"promote"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_PROMOTED	"promoted"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_DEMOTE		"demote"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_DEMOTED		"demoted"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_NOTIFY		"notify"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_NOTIFIED	"notified"
    #  pacemaker/include/crm/crm.h:#define CRMD_ACTION_STATUS		"monitor"
    # statues are (glue/include/lrm/raexec.h):
    #  EXECRA_EXEC_UNKNOWN_ERROR = -2,
    #  EXECRA_NO_RA = -1,
    #  EXECRA_OK = 0,
    #  EXECRA_UNKNOWN_ERROR = 1,
    #  EXECRA_INVALID_PARAM = 2,
    #  EXECRA_UNIMPLEMENT_FEATURE = 3,
    #  EXECRA_INSUFFICIENT_PRIV = 4,
    #  EXECRA_NOT_INSTALLED = 5,
    #  EXECRA_NOT_CONFIGURED = 6,
    #  EXECRA_NOT_RUNNING = 7,
    #  EXECRA_RUNNING_MASTER = 8,
    #  EXECRA_FAILED_MASTER = 9,
    #
    # TODO: this is very primitive; there's lots more here we can
    # learn about resources from op history, that we're not displaying.
    # But it's better than invoking crm_resource all the time...
    #
    # So...  For the moment, the rule is:
    # - if it's running anywhere (regardless of master/slave), it's Started
    # - if it's not running anywhere, but we have status, it's Stopped
    # - if we have no lrm_resource or no ops, it's Unknown, but we report
    #   this as Stopped, because anything else will be confusing.
    #
    # Return value is array of nodes on which the resource is running,
    # (empty if stopped)
    #
    def resource_state(id)

      running_on = []

      for node in @nodes
        lrm_resource = @cib.elements["cib/status/node_state[@uname='#{node[:uname]}']/lrm/lrm_resources/lrm_resource[@id='#{id}']"]
        next unless lrm_resource
        ops = {}
        lrm_resource.elements.each('lrm_rsc_op') do |op|
          ops[op.attributes['call-id'].to_i] = {
            :operation  => op.attributes['operation'],
            :rc_code    => op.attributes['rc-code'].to_i,
            :interval   => op.attributes['interval'].to_i
          }
        end
        # logic derived somewhat from pacemaker/lib/pengine/unpack.c:unpack_rsc_op()
        is_running = false
        ops.keys.sort.each do |call_id|
          # skip pending ops and notifies
          next if call_id == -1 || ops[call_id][:operation] == 'notify'

          # logger.debug "node #{node[:uname]} resource #{id}: call-id=#{call_id} operation=#{ops[call_id][:operation]} rc-code=#{ops[call_id][:rc_code]}\n"

          # do we need this?
          is_probe = ops[call_id][:operation] == 'monitor' && ops[call_id][:interval] == 0

          # TODO: what's this about expired failures? (unpack.c:1323)

          # TODO: evil magic numbers!
          case ops[call_id][:rc_code]
          when 7
            # not running on this node
            is_running = false
          when 8
            # master on this node
            is_running = true
          when 0
            # ok
            if ops[call_id][:operation] == 'stop'
              is_running = false
            else
              # anything other than a stop means we're running (although might be
              # master or slave after a promote or demote)
              is_running = true
            end
          else
            # busted somehow
            # TODO: localize
            @errors << "Failed op: node #{node[:uname]} resource #{id}: call-id=#{call_id} operation=#{ops[call_id][:operation]} rc-code=#{ops[call_id][:rc_code]}"
            # logger.debug "node #{node[:uname]} resource #{id}: call-id=#{call_id} operation=#{ops[call_id][:operation]} rc-code=#{ops[call_id][:rc_code]}\n"
          end
        end
        running_on << node[:uname] if is_running
      end

      if running_on.empty?
        # it's either unknown or not running, expand
        @expand_resources = true
      end

      return running_on
    end

    def get_primitive(res, instance = nil)
      id = res.attributes['id']
      id += ":#{instance}" if instance
      running_on = resource_state(id)
      {
        :id         => "primitive-#{id}",
        :class      => "res-primitive rs-" + if running_on.empty? then 'stopped' else 'running' end,
        # TODO: localize?  HTML-safe?
        :label      => "#{id}: " + if running_on.empty? then _('Stopped') else _('Started: ') + running_on.join(', ') end,
        
        :restype    => res.name,    # Can we get rid of this crap?
        :running_on => running_on   # Likewise?
      }
    end

    @expand_groups = []

    def get_group(res, instance = nil)
      id = res.attributes['id']
      id += ":#{instance}" if instance
      # Arguably, the above is not really true (but we need it for DIV ids for collapsibles)
      # TODO: get rid of this, it's probably weird.  Also, make sure DIV ids only contain
      # valid characaters for HTML IDs and JavaScript strings, etc.
      children = []
      open = false
      res.elements.each('primitive') do |p|
        c = get_primitive(p, instance)
        open = true if c[:running_on].empty?
        children << c
      end
      {
        :id         => "group-#{id}",
        :class      => 'res-group',
        :label      => _("Group: %{id}") % { :id => id },
        :open       => open,
        :children   => children,
        
        :restype    => res.name   # TODO: removable?
      }
    end

    @expand_clones = []

    def get_clone(res)
      id = res.attributes['id']
      children = []
      # TODO: is this the correct way to determine clone instance IDs?
      clone_max = res.attributes['clone-max'] || @nodes.count
      open = false
      if res.elements['primitive']
        for i in 0..clone_max.to_i-1 do
          c = get_primitive(res.elements['primitive'], i)
          open = true if c[:running_on].empty?
          children << c
        end
      elsif res.elements['group']
        for i in 0..clone_max.to_i-1 do
          c = get_group(res.elements['group'], i)
          open = true if c[:open]
          children << c
        end
      else
        # Again, this can't happen
      end
      {
        :id         => "clone-#{id}",
        :class      => 'res-clone',
        :label      => _("Clone Set: %{id}") % { :id => id },
        :open       => open,
        :children   => children,
        :restype    => res.name   # TODO: removable?
      }
    end

    # TODO: need failed nodes too
    @cib.elements.each('cib/configuration/resources/*') do |res|
      case res.name
        when 'primitive'
          @resources << get_primitive(res)
        when 'clone'
          @resources << get_clone(res)
        when 'group'
          @resources << get_group(res)
        else
          # This can't happen
          # TODO: whine
      end
    end

  end

  public

  def initialize
    require 'socket'
    @host = Socket.gethostname  # should be short hostname

    @cib = nil
    
    # Everything we're showing status of
    @errors     = []
    @summary    = {}
    @nodes      = []
    @resources  = []

    # TODO: Need more deps than this (see crm)
    if File.exists?('/usr/sbin/crm_mon')
      if File.executable?('/usr/sbin/crm_mon')
        @crm_status = %x[/usr/sbin/crm_mon -s 2>&1].chomp
        # TODO: this is dubious (WAR: crm_mon -s giving "status: 1, output was: Warning:offline node: hex-14")
        if $?.exitstatus == 10 || $?.exitstatus == 11
          @errors << _('%{cmd} failed (status: %{status}, output was: %{output})') %
                        {:cmd    => '/usr/sbin/crm_mon',
                         :status => $?.exitstatus,
                         :output => @crm_status }
        end
      else
        @errors << _('Unable to execute %{cmd}') % {:cmd => '/usr/sbin/crm_mon' }
      end
    else
      @errors << _('Pacemaker does not appear to be installed (%{cmd} not found)') %
                    {:cmd => '/usr/sbin/crm_mon' }
    end
  end

  # Render cluster status by default
  # (can't just render :action => 'status',
  # or we don't get the instance variables)
  def index
    redirect_to :action => 'status'
  end

  def status
    @title = _('Cluster Status')
    
    get_cluster_status
    
    @node_panel = {
      :id       => 'nodelist',
      :class    => '',
      :style    => @summary[:stack] ? '' : 'display: none;',
      # TODO: localization can't cope with singular/plural here
      :label    => _('<span id="nodecount">%d</span> nodes configured') % @nodes.count,
      :open     => @expand_nodes,
      :children => @nodes
    }
    
    @resource_panel = {
      :id       => 'reslist',
      :class    => '',
      :style    => @summary[:stack] ? '' : 'display: none;',
      # TODO: localization can't cope with singular/plural here
      :label    => _('<span id="rescount">%d</span> resources configured') % @resources.count,
      :open     => @expand_resources,
      :children => @resources
    }
    
    respond_to do |format|
      format.html # status.html.erb
      format.json {
        render :json => {
          :errors     => @errors,
          :summary    => @summary,
          :nodes      => @node_panel,
          :resources  => @resource_panel
        }
      }
    end
  end
  
end
