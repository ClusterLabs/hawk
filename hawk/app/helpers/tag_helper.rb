# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module TagHelper
  def navbar_item(text, icon)
    text_icon(
      content_tag(
        :span,
        text,
        class: "hidden-xs"
      ),
      icon
    )
  end

  def text_icon(text, icon, options = {})
    [
      text,
      icon_tag(icon, options)
    ].join("\n").html_safe
  end

  def icon_text(icon, text, options = {})
    [
      icon_tag(icon, options),
      text
    ].join("\n").html_safe
  end

  def icon_tag(icon, options = {})
    defaults = {
      class: "fa fa-#{icon} #{options.delete(:class)}".strip
    }

    content_tag(:i, "", defaults.merge(options))
  end

  def jsviews_for(name, &block)
    content = capture do
      yield
    end

    [
      "{^{for #{name}}}",
      content,
      "{{/for}}"
    ].join("\n").html_safe
  end

  def tag_refs_list
    options = @cib.resources_by_id.keys
    Rails.logger.debug "tag_refs_list << #{options}"
    constraints = @cib.constraints.map { |c| c[:id] }
    Rails.logger.debug "tag_refs_list << #{@cib.constraints}"
    options.concat constraints
    options.sort do |a, b|
      a.natcmp(b, true)
    end
  end
end
