# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class DashboardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title

  def show
    @clusters = Cluster.all

    render
  end

  def add
    if request.post?
      Rails.logger.debug "Creating from #{params[:cluster]}"
      @cluster = Cluster.new params[:cluster]
      if @cluster.save
      # flash[:success] = _("Cluster added successfully")
      # redirect_to action: "show"
        render json: @cluster.to_hash
      else
        render json: @cluster.errors, status: :unprocessable_entity
      end
    else
      @cluster = Cluster.new
      render layout: "modal"
    end
  end

  def remove
    if request.post?
      name = params[:name]
      if Cluster.remove(name)
        render json: {"name" => name }
      else
        render json: { error: _("Error removing %s") % name }, status: :unprocessable_entity
      end
    end
  end

  protected

  def set_title
    @title = _("Dashboard")
  end

  def json_request?
    request.format.json?
  end

end
