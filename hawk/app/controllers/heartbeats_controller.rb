class HeartbeatsController < ApplicationController
  before_filter :login_required

  def show
    respond_to do |format|
      format.html
    end
  end
end
