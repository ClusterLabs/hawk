module RuleHelper
  def rule_options(selected)
    options_for_select(
      [
        [_('Read'), 'read'],
        [_('Write'), 'write'],
        [_('Deny'), 'deny'],
      ],
      selected
    )
  end
end
