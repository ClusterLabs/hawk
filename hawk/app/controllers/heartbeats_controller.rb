class HeartbeatsController < ApplicationController
  before_filter :login_required

  def index
    respond_to do |format|
      format.html
    end
  end
end
