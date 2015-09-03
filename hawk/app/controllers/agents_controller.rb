# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class AgentsController < ApplicationController
  before_filter :login_required
  before_filter :set_title

  def show

    if params[:id].match /^[A-Za-z0-9:_-]+$/
      @agent = Hash.from_xml(Util.safe_x("/usr/sbin/crm_resource", "--show-metadata", params[:id]))
    else
      @agent = nil
    end


    if @agent
      respond_to do |format|
        format.html do
          render layout: "modal"
        end
        format.json do
          render json: @agent.to_json
        end
      end
    else
      respond_to do |format|
        format.any { not_found }
      end
    end
  end

  protected

  def set_title
    @title = _("Agent")
  end
end
