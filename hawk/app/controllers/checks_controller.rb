class ChecksController < ApplicationController
  before_filter :login_required
  before_filter :set_cib

  def status
    respond_to do |format|
      format.json do
        render json: @cib.meta.to_h.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end
end
