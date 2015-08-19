# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ResourcesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  before_filter :god_required, only: [:events]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Resource.ordered.to_json
      end
    end
  end

  protected

  def set_title
    @title = _('Resources')
  end

  def set_cib
    @cib = current_cib
  end

  def default_base_layout
    if params[:action] == "types"
      "withrightbar"
    else
      super
    end
  end
end
