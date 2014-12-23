module SettingHelper
  def language_options(selected)
    options = Setting.available_languages.to_a.map do |v|
      v.reverse
    end

    options_for_select(
      options,
      selected
    )
  end

  def setting_revert_button(form, role)
    form.submit(
      _('Revert'),
      class: 'btn btn-default cancel revert',
      name: 'revert',
      confirm: _('Any changes will be lost - do you wish to proceed?')
    )
  end

  def setting_apply_button(form, role)
    form.submit(
      _('Apply'),
      class: 'btn btn-primary submit',
      name: 'submit'
    )
  end
end
