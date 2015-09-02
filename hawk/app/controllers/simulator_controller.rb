# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class SimulatorController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def reset
    respond_to do |format|
      format.json do
        head :bad_request
      end
    end
  end

  def run
    respond_to do |format|
      format.json do
        head :bad_request
      end
    end
  end
end
