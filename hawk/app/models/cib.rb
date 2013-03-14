#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2013 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
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

require 'util'
require 'natcmp'
require 'rexml/document' unless defined? REXML::Document

class Cib < CibObject
  include FastGettext::Translation
  include Rails.application.routes.url_helpers    # needed for explorer_path
  protected

  # Roughly equivalent to crm_element_value() in Pacemaker
  def get_xml_attr(elem, name, default = nil)
    Util.unstring(elem.attributes[name], default)
  end

  def get_property(property, default = nil)
    # TODO(could): theoretically this xpath is a bit loose.
    e = @xml.elements["//nvpair[@name='#{property}']"]
    e ? get_xml_attr(e, 'value', default) : default
  end

  def get_resource(elem, clone_max = nil, is_ms = false)
    res = {
      :id => elem.attributes['id'],
      :attributes => {}
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
        Rails.logger.error "Got #{elem.name} without 'primitive' or 'group' child"
      end
    else
      # This really can't happen
      Rails.logger.error "Unknown resource type: #{elem.name}"
    end
    elem.elements.each("meta_attributes/nvpair/") do |nv|
      res[:attributes][nv.attributes["name"]] = nv.attributes["value"]
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
  def fix_clone_instances(resources)
    for res in resources
      if res[:clone_max]
        # There'll be a stale default instance lying around if the resource was
        # started before it was cloned (bnc#711180), so ditch it.  This is all
        # getting a bit convoluted - need to rethink...
        res[:instances].delete(:default)
        instance = 0
        while res[:instances].length < res[:clone_max]
          while res[:instances].has_key?(instance.to_s)
            instance += 1
          end
          res[:instances][instance.to_s] = { :failed_ops => [] }
        end
        res[:instances].delete(:default) if res[:instances].has_key?(:default)
        # strip any instances outside 0..clone_max if they're not running (these
        # can be present if, e.g.: you have a clone running on all nodes, then
        # set clone-max < num_nodes, in which case there'll be stopped orphans).
        res[:instances].keys.select{|i| i.to_i >= res[:clone_max]}.each do |k|
          # safe to delete if the instance is present and its only state is stopped
          res[:instances].delete(k) if res[:instances][k].keys.length == 1 && res[:instances][k].has_key?(:stopped)
        end
        res.delete :clone_max
      else
        if res.has_key?(:instances)
          res[:instances].delete_if {|k, v| k != :default}
          # Inject a default instance if there's not one, as can be the case when
          # working with shadow CIBs.
          res[:instances][:default] = { :failed_ops => [] } unless res[:instances].has_key?(:default)
        end
      end
      @resource_count += res[:instances].count if res[:instances]
      fix_clone_instances(res[:children]) if res[:children]
    end
  end

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_fencing()
  # ns is node_state element from CIB
  def determine_online_status_fencing(ns)
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = :unclean
    if in_ccm && crm_state == 'online'
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
    elsif !in_ccm && crm_state == 'offline' && !expected_up
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
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')
    exp_state   = get_xml_attr(ns, 'expected')

    # expect it to be up (more or less) if 'shutdown' is '0' or unspecified
    expected_up = get_xml_attr(ns, 'shutdown', '0') == 0

    state = :unclean
    if !in_ccm 
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

  # Notes that errors here overloads what ActiveRecord would
  # use for reporting errors when editing resources.  This
  # should almost certainly be changed.
  attr_reader :dc, :epoch, :nodes, :resources, :templates, :crm_config, :errors, :resource_count
  attr_reader :tickets
  attr_reader :resources_by_id

  def initialize(id, user, use_file = false)
    @errors = []

    if use_file
      cib_path = id
      # TODO(must): This is a bit rough
      cib_path.gsub! /[^\w-]/, ''
      cib_path = "#{Rails.root}/test/cib/#{cib_path}.xml"
      raise ArgumentError, _('CIB file "%{path}" not found') % {:path => cib_path } unless File.exist?(cib_path)
      @xml = REXML::Document.new(File.new(cib_path))
      raise RuntimeError, _('Unable to parse CIB file "%{path}"') % {:path => cib_path } unless @xml.root
    else
      raise RuntimeError, _('Pacemaker does not appear to be installed (%{cmd} not found)') %
                             {:cmd => '/usr/sbin/crm_mon' } unless File.exists?('/usr/sbin/crm_mon')
      raise RuntimeError, _('Unable to execute %{cmd}') % {:cmd => '/usr/sbin/crm_mon' } unless File.executable?('/usr/sbin/crm_mon')
      crm_status = %x[/usr/sbin/crm_mon -s 2>&1].chomp
      # TODO(should): this is dubious (WAR: crm_mon -s giving "status: 1, output was: Warning:offline node: hex-14")
      raise RuntimeError, _('%{cmd} failed (status: %{status}, output was: %{output})') %
                        {:cmd    => '/usr/sbin/crm_mon',
                         :status => $?.exitstatus,
                         :output => crm_status } if $?.exitstatus == 10 || $?.exitstatus == 11
      stdin, stdout, stderr, thread = Util.run_as(user, 'cibadmin', '-Ql')
      stdin.close
      out = stdout.read()
      stdout.close
      err = stderr.read()
      stderr.close
      case thread.value.exitstatus
      when 0
        @xml = REXML::Document.new(out)
        raise RuntimeError, _('Error invoking %{cmd}') % {:cmd => '/usr/sbin/cibadmin -Ql' } unless @xml.root
      when 54, 13
        # 13 is cib_permission_denied (used to be 54, before pacemaker 1.1.8)
        raise SecurityError, _('Permission denied for user %{user}') % {:user => user}
      else
        raise RuntimeError, _('Error invoking %{cmd}: %{msg}') % {:cmd => '/usr/sbin/cibadmin -Ql', :msg => err }
      end
    end

    @id = id

    # Special-case defaults for properties we always want to see
    @crm_config = {
      :"cluster-infrastructure"       => _('Unknown'),
      :"dc-version"                   => _('Unknown'),
      :"default-resource-stickiness"  => 0, # TODO(could): is this documented?
      :"stonith-enabled"              => true,
      :"symmetric-cluster"            => true,
      :"no-quorum-policy"             => 'stop'
    }

    # Pull in everything else
    # TODO(should): This gloms together all cluster property sets; really
    # probably only want cib-bootstrap-options?
    @xml.elements.each('cib/configuration/crm_config//nvpair') do |p|
      @crm_config[p.attributes['name'].to_sym] = get_xml_attr(p, 'value')
    end

    @nodes = []
    @xml.elements.each('cib/configuration/nodes/node') do |n|
      uname = n.attributes['uname']
      state = :unclean
      ns = @xml.elements["cib/status/node_state[@uname='#{uname}']"]
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

    @resources = []
    @resources_by_id = {}
    @resource_count = 0
    # This gives only resources capable of being instantiated, and skips (e.g.) templates
    @xml.elements.each('cib/configuration/resources/*[self::primitive or self::group or self::clone or self::master]') do |r|
      @resources << get_resource(r)
    end
    # Templates deliberately kept separate from resources, because
    # we need an easy way of listing them separately, and they don't
    # have state we care about.
    @templates = []
    @xml.elements.each('cib/configuration/resources/template') do |t|
      @templates << {
        :id => t.attributes['id'],
        :class => t.attributes['class'],
        :provider => t.attributes['provider'],
        :type => t.attributes['type']
      }
    end if Util.has_feature?(:rsc_template)

    # Iterate nodes in cib order here which makes the faked up clone & ms instance
    # IDs be in the same order as pacemaker
    for node in @nodes
      next unless node[:state] == :online
      @xml.elements.each("cib/status/node_state[@uname='#{node[:uname]}']/lrm/lrm_resources/lrm_resource") do |lrm_resource|
        id = lrm_resource.attributes['id']
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
          if op.attributes.has_key?('transition-key')
            k = op.attributes['transition-key'].split(':')
            graph_number = k[1].to_i
            expected = k[2].to_i
          end

          # skip notifies, deletes, cancels
          next if operation == 'notify' || operation == 'delete' || operation == 'cancel'

          # skip allegedly pending "last_failure" ops (hack to fix bnc#706755)
          # TODO(should): see if we can remove this in future
          next if op.attributes.has_key?('id') &&
            op.attributes['id'].end_with?("_last_failure_0") && op.attributes['call-id'].to_i == -1

          if op.attributes['call-id'].to_i == -1
            # Don't do any further processing for pending ops, but only set
            # resource state to "pending" if it's not a pending monitor
            # TODO(should): Look at doing this by "whitelist"? i.e. explicitly
            # notice pending start, stop, promote, demote, migrate_*..?
            # This would allow us to say "Staring", "Stopping", etc. in the UI.
            state = :pending if operation != "monitor"
            case operation
            when "start":
              substate = :starting
            when "stop":
              substate = :stopping
            when "promote":
              substate = :promoting
            when "demote":
              substate = :demoting
            when /^migrate/:
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
            @xml.elements.each("cib/configuration//primitive[@id='#{id.split(":")[0]}']/operations/op[@name='#{operation}']") do |e|
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

            failed_ops << { :node => node[:uname], :call_id => op.attributes['call-id'], :op => operation, :rc_code => rc_code }
            @errors << {
              :msg => _('Failed op: node=%{node}, resource=%{resource}, call-id=%{call_id}, operation=%{op}, rc-code=%{rc_code}') % {
                :node => node[:uname], :resource => id, :call_id => op.attributes['call-id'],
                :op => operation, :rc_code => rc_code },
              # Note: graph_number here might be the one *after* the one that's really interesting :-/
              :link => fail_start ? explorer_path(:from_time => fail_start, :to_time => fail_end, :display => true, :graph_number => graph_number) : ""
            }

            if ignore_failure
              failed_ops[-1][:ignored] = true
              rc_code = expected
            end
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
        end

        # TODO(should): want some sort of assert "status != :unknown" here

        # Now we've got the status on this node, let's stash it away
        (id, instance) = id.split(':')
        if @resources_by_id[id]
          # m/s slave state hack (*sigh*)
          state = :slave if @resources_by_id[id][:is_ms] && state == :started

          if !instance && @resources_by_id[id].has_key?(:clone_max)
            # Pacemaker commit 427c7fe6ea94a566aaa714daf8d214290632f837 removed
            # instance numbers from anonymous clones.  Too much of hawk wants
            # these, so we fake them back in if they're not present, by getting
            # the current maximum instance number (if present) and incrementing
            # it.
            instance = @resources_by_id[id][:instances].select {|k,v| Util.numeric?(k)}.map {|k,v| k.to_i}.max
            if instance == nil
              instance = "0"
            else
              instance = (instance + 1).to_s
            end
            # Note: instance at this point is a string because that's what
            # everythign else expects
          end

          if instance && state != :stopped && state != :unknown
            # For clones, it's possible we need to rename an instance if
            # there's already a running instance with this ID.  An instance
            # is running iff:
            # - @resources_by_id[id][:instances][instance] exists, and,
            # - there are state keys other than :stopped, :unknown or :failed_ops present
            alt_i = instance
            while @resources_by_id[id][:instances][alt_i] &&
                  @resources_by_id[id][:instances][alt_i].count{|k,v| (k != :stopped && k != :unknown && k != :failed_ops)} > 0
              alt_i = (alt_i.to_i + 1).to_s
            end
            if alt_i != instance
              Rails.logger.debug "Internally renamed #{id}:#{instance} to #{id}:#{alt_i} on #{node[:uname]}"
              instance = alt_i
            end
          else
            # instance will be nil here for regular primitives
            instance = :default
          end
          @resources_by_id[id][:instances][instance] = {} unless @resources_by_id[id][:instances][instance]
          @resources_by_id[id][:instances][instance][state] = [] unless @resources_by_id[id][:instances][instance][state]
          n = { :node => node[:uname] }
          n[:substate] = substate if substate
          @resources_by_id[id][:instances][instance][state] << n
          @resources_by_id[id][:instances][instance][:failed_ops] = [] unless @resources_by_id[id][:instances][instance][:failed_ops]
          @resources_by_id[id][:instances][instance][:failed_ops].concat failed_ops
          # NOTE: Do *not* add any more keys here without adjusting the renamer above
        else
          # It's an orphan
          # TODO(should): display this somewhere? (at least log it during testing)
        end
      end
    end

    fix_clone_instances @resources

    # More hack
    @resources_by_id.each do |k,v|
      @resources_by_id[k].delete :is_ms
      # Need to inject a default instance if we don't have any state
      # (e.g. during cluster bringup) else the panel renderer chokes.
      if @resources_by_id[k][:instances] && @resources_by_id[k][:instances].empty?
        # Always include empty failed_ops array (JS status updater relies on it)
        @resources_by_id[k][:instances][:default] = { :failed_ops => [] }
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
    
    @epoch = "#{get_xml_attr(@xml.root, 'admin_epoch')}:#{get_xml_attr(@xml.root, 'epoch')}:#{get_xml_attr(@xml.root, 'num_updates')}";

    # Tickets will always have a granted property (boolean).  They may also
    # have a last-granted timestamp too, but this will only be present if a
    # ticket has ever been granted - it won't be there for tickets we only
    # pick up from rsc_ticket constraints.
    @tickets = {}
    @xml.elements.each("cib/status/tickets/ticket_state") do |ts|
      t = ts.attributes["id"]
      @tickets[t] = {
        :granted => Util.unstring(ts.attributes["granted"], false),
        :standby => Util.unstring(ts.attributes["standby"], false)
      }
      @tickets[t][:"last-granted"] = ts.attributes["last-granted"] if ts.attributes["last-granted"]
    end
    @xml.elements.each("cib/configuration/constraints/rsc_ticket") do |rt|
      t = rt.attributes["ticket"]
      @tickets[t] = { :granted => false } unless @tickets[rt.attributes["ticket"]]
    end

  end

end
