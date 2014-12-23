module UserHelper
  def user_options(selected)
    options_for_select(
      User.ordered.map(&:id),
      selected
    )
  end

  def user_revert_button(form, user)
    form.submit(
      _('Revert'),
      class: 'btn btn-default cancel revert simple-hidden',
      name: 'revert',
      confirm: _('Any changes will be lost - do you wish to proceed?')
    )
  end

  def user_apply_button(form, user)
    form.submit(
      _('Apply'),
      class: 'btn btn-primary submit',
      name: 'submit'
    )
  end

  def user_create_button(form, user)
    form.submit(
      _('Create'),
      class: 'btn btn-primary submit',
      name: 'submit'
    )
  end
end
