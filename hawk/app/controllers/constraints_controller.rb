# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ConstraintsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  before_filter :god_required, only: [:events]

  def types
    respond_to do |format|
      format.html
    end
  end

  protected

  def set_title
    @title = _('Constraints')
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
