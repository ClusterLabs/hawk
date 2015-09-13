# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module CrmConfigHelper
  def crm_config_revert_button(form, role)
    form.submit(
      _("Revert"),
      class: "btn btn-default cancel revert",
      name: "revert",
      confirm: _("Any changes will be lost - do you wish to proceed?")
    )
  end

  def crm_config_apply_button(form, role)
    form.submit(
      _("Apply"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end
end
