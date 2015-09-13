# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module ProfileHelper
  def language_options(selected)
    options = Profile.available_languages.to_a.map do |v|
      v.reverse
    end

    options_for_select(
      options,
      selected
    )
  end

  def profile_revert_button(form, role)
    form.submit(
      _("Revert"),
      class: "btn btn-default cancel revert",
      name: "revert",
      confirm: _("Any changes will be lost - do you wish to proceed?")
    )
  end

  def profile_apply_button(form, role)
    form.submit(
      _("Apply"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end
end
