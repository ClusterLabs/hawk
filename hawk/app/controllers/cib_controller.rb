# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class CibController < ApplicationController
  before_filter :login_required
  skip_before_filter :verify_authenticity_token

  def show
    respond_to do |format|
      format.json do
        render json: current_cib.status(params[:id] == "mini")
      end
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :not_found
      end
      format.any { head :not_found  }
    end
  rescue SecurityError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :forbidden
      end
      format.any { head :forbidden  }
    end
  rescue RuntimeError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :internal_server_error
      end
      format.any { head :internal_server_error  }
    end
  end

  def options
    respond_to do |format|
      format.json do
        render json: {}, status: 200
      end
    end
  end
end
