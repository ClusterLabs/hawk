# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

class AgentsController < ApplicationController
  before_action :login_required
  before_action :set_title

  def show
    if params[:id].start_with? "@"
      name = params[:id][1..-1]
      template = Hash.from_xml(Util.safe_x("/usr/sbin/cibadmin", "-l", "--query", "--xpath", "//template[@id='#{name}']"))
      Rails.logger.debug "Template: #{template}"
      if template
        template = template["template"]
        Rails.logger.debug "#{template}"
        name = ""
        name = name + template["class"] + ":" if template["class"]
        name = name + template["provider"] + ":" if template["provider"]
        @name = name + template["type"]
      end
    else
      @name = params[:id]
    end
    @agent = Hash.from_xml(Util.get_meta_data(@name))

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
