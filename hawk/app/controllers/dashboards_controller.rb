# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

class DashboardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title

  def show
    @clusters = Cluster.all

    render layout: "dashboard"
  end

  def add
    if request.post?
      @cluster = Cluster.new params[:cluster]
      if @cluster.save
        flash[:success] = _("Cluster added successfully")
      else
        flash[:alert] = _("Failed to add cluster")
      end
      redirect_to action: "show"
    else
      @cluster = Cluster.new interval: 30
      render layout: "modal"
    end
  end

  def remove
    if request.post?
      name = params[:name]
      if Cluster.remove(name)
        flash[:success] = _("Cluster removed successfully")
      else
        flash[:alert] = _("Failed to remove cluster")
      end
      redirect_to action: "show"
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
