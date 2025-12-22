# Copyright (c) 2025 Aleksei Burlakov <aburlakov@suse.com>
# See COPYING for license.

class InternalAuthController < ApplicationController
  # internal endpoint; no CSRF and no redirects
  skip_before_action :verify_authenticity_token

  def show
    return head :forbidden unless request.local?

    if logged_in?
      render json: { ok: true, user: current_user }, status: 200
    else
      render json: { ok: false }, status: 403
    end
  end
end
