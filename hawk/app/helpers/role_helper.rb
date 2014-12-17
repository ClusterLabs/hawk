module RoleHelper
  def role_options(selected)
    options_for_select(
      Role.ordered.map(&:id),
      selected
    )
  end

  def role_revert_button(form, role)
    form.submit(
      _('Revert'),
      class: 'btn btn-default revert',
      name: 'revert',
      confirm: _('Any changes will be lost - do you wish to proceed?'),
      'rv-show' => 'allow_revert'
    )
  end

  def role_apply_button(form, role)
    form.submit(
      _('Apply'),
      class: 'btn btn-primary submit',
      name: 'submit',
      'rv-enabled' => 'allow_submit'
    )
  end

  def role_create_button(form, role)
    form.submit(
      _('Create'),
      class: 'btn btn-primary submit',
      name: 'submit',
      'rv-enabled' => 'allow_submit'
    )
  end
end
