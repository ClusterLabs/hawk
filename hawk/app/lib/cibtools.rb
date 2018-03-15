# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

# Tools for manipulating the CIB XML.
require 'util'


module CibTools

  # Roughly equivalent to crm_element_value() in Pacemaker
  def get_xml_attr(elem, name, default = nil)
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
end
