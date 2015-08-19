# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class StatesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def show
    respond_to do |format|
      format.html
    end
  end

  protected

  def set_title
    @title = _("Status")
  end

  def set_cib
    @cib = current_cib
  end
end
