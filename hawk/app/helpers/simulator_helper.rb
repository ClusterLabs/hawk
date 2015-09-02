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
end
