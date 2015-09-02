# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

module SimulatorHelper
  def node_actions
    [:online, :offline, :unclean]
  end

  def op_actions
    [:monitor, :start, :stop, :promote, :demote, :notify, :migrate_to, :migrate_from]
  end

  def ticket_actions
    [:grant, :revoke]
  end

  def op_results
    {
      0 => _('success'),
      1 => _('generic error'),
      2 => _('incorrect arguments'),
      3 => _('unimplemented action'),
      4 => _('insufficient permissions'),
      5 => _('installation error'),
      6 => _('configuration error'),
      7 => _('not running'),
      8 => _('running (master)'),
      9 => _('failed (master)')
    }
  end

  def resource_instances
    [].tap do |instances|
      current_cib.resources_by_id.each do |name, rsc|
        next unless rsc.has_key? :instances

        id = name
        rsc[:instances].each do |iname, inode|
          if iname == "default"
            instances.push id
          else
            instances.push "#{id}:#{iname}"
          end
        end
      end
    end
  end
end
