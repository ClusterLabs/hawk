# Copyright (c) 2022 SUSE LLC
# See COPYING for license.

class ErrorsController < ActionController::Base
  protect_from_forgery with: :null_session

  def not_found
    respond_to do |format|
      format.html do
        render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
      end
      format.any do
        head :not_found
      end
    end
  end
end
