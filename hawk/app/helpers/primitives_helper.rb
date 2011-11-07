module PrimitivesHelper
  def is_template?
    controller.controller_name == "templates"
  end

  def id_prefix
    is_template? ? "template" : "primitive"
  end
end
