# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def gettext_js
    render :partial => 'gettext/gettext'
  end
end
