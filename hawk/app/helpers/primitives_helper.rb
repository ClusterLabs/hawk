module PrimitivesHelper
  def is_template?
    controller.controller_name == "templates"
  end

  def id_prefix
    is_template? ? "template" : "primitive"
  end

  # The view calls Primitive.types to get a list of types for the current
  # class and provider.  When creating a new primitive for the first time,
  # the resource defaults to r_class=ocf, but r_provider='' (see comment in
  # Primitive model for why).  If we call Primitive.types with an empty
  # provider, it will return all available resource types of *all* classes.
  # We don't want that - we only want the types for whatever the default
  # provider is, as it appears in the provider drop-down list.  So here,
  # if r_provider is empty, but there *are* available providers for r_class,
  # we return the first provider (this is passed to Primitive.types in the
  # view)
  def default_provider
    if !@res.r_provider.empty?
      @res.r_provider
    elsif Primitive.classes_and_providers[:r_providers].has_key?(@res.r_class)
      Primitive.classes_and_providers[:r_providers][@res.r_class][0]
    else
      ''
    end
  end
end
