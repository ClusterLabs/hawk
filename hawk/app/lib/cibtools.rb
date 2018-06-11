# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

# Tools for manipulating the CIB XML.
require 'util'


module CibTools

  # Roughly equivalent to crm_element_value() in Pacemaker
  def get_xml_attr(elem, name, default = nil)
    return nil if elem.nil?
    Util.unstring(elem.attributes[name], default)
  end
  module_function :get_xml_attr


  # Format the epoch string "admin_epoch:epoch:num_updates"
  def epoch_string(elem)
    "#{CibTools.get_xml_attr(elem, 'admin_epoch', '0')}:#{CibTools.get_xml_attr(elem, 'epoch', '0')}:#{CibTools.get_xml_attr(elem, 'num_updates', '0')}";
  end
  module_function :epoch_string


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
  module_function :determine_online_status_fencing

  # transliteration of pacemaker/lib/pengine/unpack.c:determine_online_status_no_fencing()
  # ns is node_state element from CIB
  # TODO(could): can we consolidate this with determine_online_status_fencing?
  def determine_online_status_no_fencing(ns)
    in_ccm      = get_xml_attr(ns, 'in_ccm')
    crm_state   = get_xml_attr(ns, 'crmd')
    join_state  = get_xml_attr(ns, 'join')

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
  module_function :determine_online_status_no_fencing

  def determine_online_status(ns, stonith_enabled)
    if stonith_enabled
      return determine_online_status_fencing(ns)
    else
      return determine_online_status_no_fencing(ns)
    end
  end
  module_function :determine_online_status

  def rc_desc(rc)
    case rc
    when 0
      _('success')
    when 1
      _('generic error')
    when 2
      _('incorrect arguments')
    when 3
      _('unimplemented action')
    when 4
      _('insufficient permissions')
    when 5
      _('installation error')
    when 6
      _('configuration error')
    when 7
      _('not running')
    when 8
      _('promoted')
    when 9
      _('failed (promoted)')
    else
      _('other')
    end
  end
  module_function :rc_desc

  def sort_ops(a, b)
    a_op = a.attributes['operation']
    b_op = b.attributes['operation']
    a_call_id = a.attributes['call-id'].to_i
    b_call_id = b.attributes['call-id'].to_i
    if a_call_id != -1 && b_call_id != -1
      # Normal case, neither op is pending, call-id wins
      a_call_id <=> b_call_id
    elsif a_op.starts_with?('migrate_') || b_op.starts_with?('migrate_')
      # Special case for pending migrate ops, beacuse stale ops hang around
      # in the CIB (see lf#2481).  There's a couple of things to do here:
      a_key = a.attributes['transition-key']
      b_key = b.attributes['transition-key']
      a_key_split = a_key.split(':')
      b_key_split = b_key.split(':')
      if a_key == b_key
        # 1) if the transition keys match, newer call-id wins (ensures bogus
        # pending ops lose to immediately subsequent start/stop).
        a_call_id <=> b_call_id
      elsif a_key_split[3] == b_key_split[3]
        # 2) if the transition keys don't match but the transitioner UUIDs
        # *do* match, the migrate is either old (predating a start/stop that
        # occurred after a migrate's regular start/stop), or new (the current
        # pending op), in which case we assume the larger graph number is the
        # most recent op (this will break if uint64_t ever wraps).
        a_key_split[1].to_i <=> b_key_split[1].to_i
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
        b_call_id <=> a_call_id
      end
    elsif a_op == b_op && a_key == b_key
      # Same operation, same transition key, and one op is allegedly pending.
      # This is a lie (see bnc#879034), so make newer call-id win hand have
      # bogus pending op lose (similar to above special case for migrate ops)
      a_call_id <=> b_call_id
    elsif a_call_id == -1
      1                                         # make pending start/stop op most recent
    elsif b_call_id == -1
      -1                                        # likewise
    else
      Rails.logger.error "Inexplicable op sort error (this can't happen)"
      a_call_id <=> b_call_id
    end
  end
  module_function :sort_ops

  # TODO(should): evil magic numbers!
  # The operation and RC code tells us the state of the resource on this node
  # when rc=0, anything other than a stop means we're running
  # (might be slave after a demote)
  # TODO(must): verify this demote business
  def op_rc_to_state(operation, rc, state)
    case rc
    when 7
      :stopped
    when 8
      :master
    when 0
      case operation
      when 'stop', 'migrate_to'
        :stopped
      when 'promote'
        :master
      else
        :started
      end
    else
      state
    end
  end
  module_function :op_rc_to_state

  def rsc_state_from_lrm_rsc_op(xml, node_uname, rsc_id)
    xml.elements.each("cib/status/node_state[@uname='#{node_uname}']/lrm/lrm_resources/lrm_resource[@id='#{rsc_id}']") do |lrm_resource|
      # logic derived somewhat from pacemaker/lib/pengine/unpack.c:unpack_rsc_op()
      state = :unknown
      ops = []
      lrm_resource.elements.each('lrm_rsc_op') do |op|
        ops << op
      end
      ops.sort { |a, b| CibTools.sort_ops(a, b) }.each do |op|
        operation = op.attributes['operation']
        id = op.attributes['id']
        call_id = op.attributes['call-id'].to_i
        rc_code = op.attributes['rc-code'].to_i
        # Cope with missing transition key (e.g.: in multi1.xml CIB from pengine/test10)
        # TODO(should): Can we handle this better?  When is it valid for the transition
        # key to not be there?
        expected = rc_code
        if op.attributes.key?('transition-key')
          k = op.attributes['transition-key'].split(':')
          expected = k[2].to_i
        end

        # skip notifies, deletes, cancels
        next if ['notify', 'delete', 'cancel'].include? operation

        # skip allegedly pending "last_failure" ops (hack to fix bnc#706755)
        # TODO(should): see if we can remove this in future
        next if !id.nil? && id.end_with?("_last_failure_0") && call_id == -1

        if call_id == -1
          # Don't do any further processing for pending ops, but only set
          # resource state to "pending" if it's not a pending monitor
          # TODO(should): Look at doing this by "whitelist"? i.e. explicitly
          # notice pending start, stop, promote, demote, migrate_*..?
          # This would allow us to say "Staring", "Stopping", etc. in the UI.
          state = :pending if operation != "monitor"
          next
        end

        is_probe = operation == 'monitor' && op.attributes['interval'].to_i.zero?
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

          if ignore_failure
            rc_code = expected
          elsif operation == "stop"
            # We have a failed stop, the resource is failed (bnc#879034)
            state = :failed
          end
        end

        state = CibTools.op_rc_to_state operation, rc_code, state
      end

      return state
    end
    :unknown
  end
  module_function :rsc_state_from_lrm_rsc_op
end
