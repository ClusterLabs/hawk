# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class PagesController < ApplicationController
  before_filter :login_required

  layout :detect_modal_layout,
    only: [:help]

  def index
    @title = _("Welcome")

    respond_to do |format|
      format.html do
        redirect_to cib_path(cib_id: view_context.current_cib.id), status: 301
      end
    end
  end

  def help
    @title = _("Help")

    respond_to do |format|
      format.html
    end
  end

  protected

  def detect_modal_layout
    if request.xhr?
      "modal"
    else
      detect_current_layout
    end
  end
end
