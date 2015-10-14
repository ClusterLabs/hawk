# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module FormHelper
  def boolean_options(selected)
    options_for_select(
      [
        [_("Yes"), "true"],
        [_("No"), "false"]
      ],
      selected
    )
  end

  def revert_button(form, record)
    form.submit(
      _("Revert"),
      class: "btn btn-default cancel revert simple-hidden",
      name: "revert",
      confirm: _("Any changes will be lost - do you wish to proceed?")
    )
  end

  def apply_button(form, record)
    form.submit(
      _("Apply"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end

  def create_button(form, record)
    form.submit(
      _("Create"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end

  def add_button(form, record)
    form.submit(
      _("Add"),
      class: "btn btn-primary submit",
      name: "submit"
    )
  end

  def errors_for(record)
    unless record.errors[:base].empty? || record.errors[:base].first.nil?
      content_tag(
        :div,
        record.errors[:base].first.html_safe,
        class: "alert alert-danger",
        role: "alert"
      )
    end
  end

  def form_for(record, options, &proc)
    unless options.fetch(:bootstrap, true)
      return super(record, options, &proc)
    end

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
