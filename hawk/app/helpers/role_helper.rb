# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module RoleHelper
  def role_options(selected)
    options_for_select(
      Role.ordered.map(&:id),
      selected
    )
  end

  def role_revert_button(form, role)
    form.submit(
      _("Revert"),
      class: "btn btn-default cancel revert simple-hidden",
      name: "revert",
      confirm: _("Any changes will be lost - do you wish to proceed?")
    )
  end

  def role_apply_button(form, role)
    form.submit(
      _("Apply"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end

  def role_create_button(form, role)
    form.submit(
      _("Create"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end
end
