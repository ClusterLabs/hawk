# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ChecksController < ApplicationController
  before_filter :login_required

  def status
    respond_to do |format|
      format.json do
        @cib = current_cib
        render json: @cib.meta.to_h.to_json
      end
      format.any { not_found  }
    end
  end
end
