#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

class PagesController < ApplicationController
  before_filter :login_required

  layout :detect_modal_layout,
    only: [:help]

  def index
    @title = _("Welcome")

    respond_to do |format|
      format.html do
        redirect_to cib_state_path(cib_id: view_context.current_cib.id), status: 301
      end
    end
  end

  def help
    @title = _("Help")

    respond_to do |format|
      format.html
    end
  end

  def monitor
    result = Open3.popen3("/usr/sbin/hawk_monitor") do |i, o|
      o.read
    end

    headers, body = result.split("\n\n", 2)

    headers.split("\n").each do |header|
      name, value = header.split(":")
      response.headers[name] = value.strip
    end

    render json: body
  end

  def commands
    @title = _("Commands")

    @cmds = CrmEvents.instance.cmds

    respond_to do |format|
      format.html
      format.json do
        render json: @cmds
      end
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
