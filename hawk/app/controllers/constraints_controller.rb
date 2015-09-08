# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ConstraintsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Constraint.all.to_json
      end
    end
  end

  def status
    respond_to do |format|
      format.json do
        render json: @cib.constraints.to_json
      end
    end
  end

  def types
    respond_to do |format|
      format.html
    end
  end

  def show
    @constraint = Constraint.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  protected

  def set_title
    @title = _("Constraints")
  end

  def set_cib
    @cib = current_cib
  end

  def default_base_layout
    if ["index", "types"].include? params[:action]
      "withrightbar"
    else
      if params[:action] == "show"
        "modal"
      else
        super
      end
    end
  end
end
