# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

class CommandsController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib

  def index
    @cmds = CrmEvents.instance.cmds
    respond_to do |format|
      format.html
      format.json do
        render json: @cmds
      end
    end
  end

  protected

  def set_title
    @title = _("Command Log")
  end

  def set_cib
    @cib = current_cib
  end
end
