# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module FormHelper
  def boolean_options(selected)
    sel = selected.to_s.downcase
    vals = [[_("Yes"), "true"], [_("No"), "false"]]
    vals = [[_("True"), "true"], [_("False"), "false"]] if ["true", "false"].include? sel
    vals = [[_("Yes"), "yes"], [_("No"), "no"]] if ["yes", "no"].include? sel
    vals = [[_("On"), "on"], [_("Off"), "off"]] if ["on", "off"].include? sel
    options_for_select(vals, sel)
  end

  def revert_button(form, _record)
    form.submit(
      _("Revert"),
      class: "btn btn-default cancel revert simple-hidden",
      name: "revert",
      confirm: _("Any changes will be lost - do you wish to proceed?")
    )
  end

  def apply_button(form, _record)
    form.submit(_("Apply"), class: "btn btn-primary submit", name: "submit")
  end

  def create_button(form, _record)
    form.submit(_("Create"), class: "btn btn-primary submit", name: "submit")
  end

  def add_button(form, _record)
    form.submit(_("Add"), class: "btn btn-primary submit", name: "submit")
  end

  def errors_for(record)
    content_tag(
      :div,
      simple_format(record.errors[:base].first), class: "alert alert-danger", role: "alert"
    ) unless record.errors[:base].empty? || record.errors[:base].first.nil?
  end

  def form_for(record, options, &proc)
    return super(record, options, &proc) unless options.fetch(:bootstrap, true)

    options[:validate] = true

    options[:builder] ||= Hawk::FormBuilder

    options[:html] ||= {}
    options[:html][:role] ||= "form"
    options[:html][:class] ||= ""

    if options.fetch(:inline, false)
      options[:html][:class] = [
        "form-inline",
        options[:html][:class]
      ].join(" ")
    end

    if options.fetch(:horizontal, false)
      options[:html][:class] = [
        "form-horizontal",
        options[:html][:class]
      ].join(" ")
    end

    if options.fetch(:simple, false)
      options[:html][:class] = [
        "form-simple",
        options[:html][:class]
      ].join(" ")
    end

    options[:html][:class].strip!

    super(record, options, &proc)
  end
end
