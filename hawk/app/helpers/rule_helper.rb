# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module RuleHelper
  def rule_options(selected)
    options_for_select(
      [
        [_("Read"), "read"],
        [_("Write"), "write"],
        [_("Deny"), "deny"],
      ],
      selected
    )
  end
end
