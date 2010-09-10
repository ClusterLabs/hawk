#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
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

require 'natcmp'
require 'util'
require 'rexml/document' unless defined? REXML::Document

class MainController < ApplicationController
  before_filter :login_required

  # TODO(should): all this private stuff really belongs elsewhere
  # (models for cluster, nodes, resources anybody?)
  private

  # Invoke some command, returning OK or JSON error as appropriate
  def invoke(*cmd)
    stdin, stdout, stderr = Util.popen3(*cmd)
    if $?.exitstatus == 0
      head :ok
    else
      render :status => 500, :json => {
        :error  => _('%{cmd} failed (status: %{status})') % { :cmd => cmd.join(' '), :status => $?.exitstatus },
        :stderr => stderr.readlines
      }
    end
  end

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

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_fencing()
  # TODO(could): constants for states? (dead, active, etc.)
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
  # TODO(could): constants for states? (dead, active, etc.)
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
    @cib = REXML::Document.new(%x[/usr/sbin/cibadmin -Ql 2>/dev/null])
    # If this failed, there'll be no root element; bail out leaving
    # everything empty.  Status display can key off non-empty @summary
    return unless @cib.root

    @cib_epoch = "#{get_xml_attr(@cib.root, 'admin_epoch')}:#{get_xml_attr(@cib.root, 'epoch')}:#{get_xml_attr(@cib.root, 'num_updates')}"

    @summary[:stack]    = get_property('cluster-infrastructure') || _('Unknown')
    @summary[:version]  = get_property('dc-version') || _('Unknown')
    # trim version back to 12 chars (same length hg usually shows),
    # enough to know what's going on, and less screen real-estate
    ver_trimmed = @summary[:version].match(/.*-[a-f0-9]{12}/)
    @summary[:version]  = ver_trimmed[0] if ver_trimmed
    # crmadmin will wait a long time if the cluster isn't up yet - cap it at 100ms
    @summary[:dc]       = %x[/usr/sbin/crmadmin -t 100 -D 2>/dev/null].strip
    s = @summary[:dc].rindex(' ')
    @summary[:dc].slice!(0, s + 1) if s
    @summary[:dc]       = _('Unknown') if @summary[:dc].empty?
    # default values per pacemaker 1.0 docs
    @summary[:default_resource_stickiness] = get_property('default-resource-stickiness', '0') # TODO(could): is this documented?
    @summary[:stonith_enabled]             = get_property('stonith-enabled', 'true') ? _('Yes') : _('No')
    @summary[:symmetric_cluster]           = get_property('symmetric-cluster', 'true') ? _('Yes') : _('No')
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
                # TODO(could): is the above actually a sane test?
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
      # map actual states back to generic visuals
      case node[:state]
      when 'online'
        className = 'active'
        label = _('Online')
      when 'offline'
        className = 'inactive'
        label = _('Offline')
      when 'pending'
        className = 'transient'
        label = _('Pending')
      when 'standby'
        className = 'inactive'
        label = _('Standby')
      when 'unclean'
        className = 'error'
        ## FOO
        label = _('Unclean')
      else
        # This can't happen...
        className = 'error'
      end

      @nodes << {
        :uname      => node[:uname],              # needed for resource status, not used by renderer
        :id         => "node::#{node[:uname]}",
        :className  => "node ns-#{className}",
        :label      => _('%{node}: %{status}') % { :node => node[:uname], :status => label },
        :menu       => true
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
    # TODO(should): this is very primitive; there's lots more here we can
    # learn about resources from op history, that we're not displaying.
    # But it's better than invoking crm_resource all the time...
    #
    # So...  For the moment, the rule is:
    # - if it's running anywhere Started or Master
    # - if it's not running anywhere, but we have status, it's Stopped
    # - if we have no lrm_resource or no ops, it's Unknown, but we report
    #   this as Stopped, because anything else will be confusing.
    #
    # Return value is hash of arrays of nodes on which the resource is running or master
    # (arrays are empty if stopped)
    #
    # TODO(should): This actually all needs reworking - we should probably just be
    # reading the LRM status section then synthesizing primitive instances from there
    # rather than relying on what we think is configured (we'll miss orphans with current
    # implementation, also it's harder to cope with gaps in clone instance IDs, etc.)
    #
    def resource_state(id)

      running_on = []
      master_on  = []
      pending_on = []

      for node in @nodes
        lrm_resource = @cib.elements["cib/status/node_state[@uname='#{node[:uname]}']/lrm/lrm_resources/lrm_resource[@id='#{id}']"]
        next unless lrm_resource

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
            if operation == 'stop'
              state = :stopped
            elsif operation == 'promote'
              state = :master
            else
              # anything other than a stop means we're running (although might be
              # master or slave after a promote or demote)
              state = :running
            end
          end
          if !is_probe && rc_code != expected
            # busted somehow
            @errors << _('Failed op: node=%{node}, resource=%{resource}, call-id=%{call_id}, operation=%{op}, rc-code=%{rc_code}') %
              { :node => node[:uname], :resource => id, :call_id => op.attributes['call-id'], :op => operation, :rc_code => rc_code }
          end
        end
        running_on << node[:uname] if state == :running
        master_on  << node[:uname] if state == :master
        pending_on << node[:uname] if state == :pending
      end

      if running_on.empty? && master_on.empty?
        # it's either unknown, not running, or pending expand
        @expand_resources = true
      end

      return { :started => running_on, :master => master_on, :pending => pending_on }
    end

    # TODO(should): this is_ms thing is a bit ugly (see comment above resource_state about reworking this)
    def get_primitive(res, instance = nil, is_ms = false)
      id = res.attributes['id']
      id += ":#{instance}" if instance
      running_on = resource_state(id)
      status_class = 'res-primitive'
      if !running_on[:master].empty? then
        label = _('%{id}: Master: %{nodelist}') % { :id => id, :nodelist => running_on[:master].join(', ') }
        status_class += ' rs-active rs-master'
      elsif !running_on[:pending].empty? then
        label = _('%{id}: Pending: %{nodelist}') % { :id => id, :nodelist => running_on[:pending].join(', ') }
        status_class += ' rs-transient'
      elsif !running_on[:started].empty? then
        status_class += ' rs-active'
        if is_ms
          label = _('%{id}: Slave: %{nodelist}') % { :id => id, :nodelist => running_on[:started].join(', ') }
          status_class += ' rs-slave'
        else
          label = _('%{id}: Started: %{nodelist}') % { :id => id, :nodelist => running_on[:started].join(', ') }
        end
      else
        label = _('%{id}: Stopped') % { :id => id }
        status_class += ' rs-inactive'
      end
      {
        :id         => "resource::#{id}",
        :className  => status_class,
        :label      => label,
        :active     => !running_on[:master].empty? || !running_on[:started].empty?
      }
    end

    @expand_groups = []

    def get_group(res, instance = nil, is_ms = false)
      id = res.attributes['id']
      id += ":#{instance}" if instance
      status_class = 'rs-active'
      # Arguably, the above is not really true (but we need it for DIV ids for collapsibles)
      # TODO(should): get rid of this, it's probably weird.  Also, make sure DIV ids only contain
      # valid characaters for HTML IDs and JavaScript strings, etc.
      children = []
      open = false
      res.elements.each('primitive') do |p|
        c = get_primitive(p, instance, is_ms)
        open = true unless c[:active]
        status_class = 'rs-inactive' unless c[:className].include? 'rs-active'    # TODO(could): only handles two states - do we care?
        children << c
      end
      {
        :id         => "resource::#{id}",
        :className  => "res-group #{status_class}",
        :label      => _("Group: %{id}") % { :id => id },
        :open       => open,
        :children   => children
      }
    end

    @expand_clones = []

    def get_clone(res)
      id = res.attributes['id']
      children = []
      status_class = 'rs-active'
      # TODO(must): this is *not* the correct way to determine clone IDs: there may be gaps, and there may be more than clone-max!
      clone_max = res.attributes['clone-max'] || @nodes.length
      open = false
      if res.elements['primitive']
        for i in 0..clone_max.to_i-1 do
          c = get_primitive(res.elements['primitive'], i, res.name == 'master')
          open = true unless c[:active]
          status_class = 'rs-inactive' unless c[:className].include? 'rs-active'    # TODO(should): only handles two states - do we care?
          children << c
        end
      elsif res.elements['group']
        for i in 0..clone_max.to_i-1 do
          c = get_group(res.elements['group'], i, res.name == 'master')
          open = true if c[:open]
          status_class = 'rs-inactive' unless c[:className].include? 'rs-active'    # TODO(should): only handles two states - do we care?
          children << c
        end
      else
        # Again, this can't happen
      end
      status_class += ' res-ms' if res.name == 'master'
      {
        :id         => "resource::#{id}",
        :className  => "res-clone #{status_class}",
        :label      => res.name == 'master' ? _("Master/Slave Set: %{id}") % { :id => id } : _("Clone Set: %{id}") % { :id => id },
        :open       => open,
        :children   => children
      }
    end

    @cib.elements.each('cib/configuration/resources/*') do |res|
      case res.name
        when 'primitive'
          @resources << get_primitive(res)
        when 'clone', 'master'
          @resources << get_clone(res)
        when 'group'
          @resources << get_group(res)
        else
          # This can't happen
          # TODO(could): whine
      end
    end

  end

  public

  def initialize
    require 'socket'
    @host = Socket.gethostname  # should be short hostname

    @cib = nil
    
    # Everything we're showing status of
    @cib_epoch  = ""
    @errors     = []
    @summary    = {}
    @nodes      = []
    @resources  = []

    # TODO(should): Need more deps than this (see crm)
    if File.exists?('/usr/sbin/crm_mon')
      if File.executable?('/usr/sbin/crm_mon')
        @crm_status = %x[/usr/sbin/crm_mon -s 2>&1].chomp
        # TODO(should): this is dubious (WAR: crm_mon -s giving "status: 1, output was: Warning:offline node: hex-14")
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

  def gettext
    render :partial => 'gettext'
  end

  def status
    @title = _('Cluster Status')
    
    get_cluster_status
    
    @node_panel = {
      :id         => 'nodelist',
      :className  => '',
      :style      => @summary[:version] ? '' : 'display: none;',
      :label      => n_('1 node configured', '%{num} nodes configured', @nodes.length) % { :num => @nodes.length },
      :open       => @expand_nodes,
      :children   => @nodes
    }
    
    @resource_panel = {
      :id         => 'reslist',
      :className  => '',
      :style      => @summary[:version] ? '' : 'display: none;',
      :label      => n_('1 resource configured', '%{num} resources configured', @resources.length) % { :num => @resources.length },
      :open       => @expand_resources,
      :children   => @resources
    }
    
    respond_to do |format|
      format.html # status.html.erb
      format.json {
        render :json => {
          :cib_epoch  => @cib_epoch,
          :errors     => @errors,
          :summary    => @summary,
          :nodes      => @node_panel,
          :resources  => @resource_panel
        }
      }
    end
  end

  # standby/online (op validity guaranteed by routes)
  def node_standby
    if params[:node]
      invoke '/usr/sbin/crm_standby', '-N', params[:node], '-v', params[:op] == 'standby' ? 'on' : 'off'
    else
      render :status => 400, :json => {
        :error => _('Required parameter "node" not specified')
      }
    end
  end

  def node_fence
    if params[:node]
      invoke '/usr/sbin/crm_attribute', '-t', 'status', '-U', params[:node], '-n', 'terminate', '-v', 'true'
    else
      render :status => 400, :json => {
        :error => _('Required parameter "node" not specified')
      }
    end
  end

#  def node_mark
#    head :ok
#  end

  # start, stop, etc. (op validity guaranteed by routes)
  # TODO(should): exceptions to handle missing params
  def resource_op
    if params[:resource]
      invoke '/usr/sbin/crm', 'resource', params[:op], params[:resource]
    else
      render :status => 400, :json => {
        :error => _('Required parameter "resource" not specified')
      }
    end
  end

  def resource_migrate
    if params[:resource] && params[:node]
      invoke '/usr/sbin/crm', 'resource', 'migrate', params[:resource], params[:node]
    else
      render :status => 400, :json => {
        :error => _('Required parameters "resource" and "node" not specified')
      }
    end
  end

end
