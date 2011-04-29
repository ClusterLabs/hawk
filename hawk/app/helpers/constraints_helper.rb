module ConstraintsHelper
  # Gives role or action suffix
  # (":Master", ":Started", ":promote", ":start" etc.).
  def role_string(klass, hash)
    role = klass == Colocation ? hash[:role] : hash[:action]
    role ? ":#{role}" : ""
  end

  # prettify colocation or order constraint
  def rsc_set(con)
    con.resources.map {|set|
      if set[:sequential]
        set[:resources].map {|rsc|
          "<span>" + h(rsc[:id] + role_string(con.class, set)) + "</span>"
        }.join(image_tag('arrow-right.png', :alt => '&rarr;'))
      else
        "<span>" + set[:resources].map {|rsc|
          h(rsc[:id] + role_string(con.class, set))
        }.join(" ") + "</span>"
      end
    }.join(image_tag('arrow-right.png', :alt => '&rarr;'))
  end
end
