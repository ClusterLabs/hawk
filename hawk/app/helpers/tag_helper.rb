module TagHelper
  def navbar_item(text, icon)
    text_icon(
      content_tag(
        :span,
        text,
        class: 'hidden-xs'
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
end
