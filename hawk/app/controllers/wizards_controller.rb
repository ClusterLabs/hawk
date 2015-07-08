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

class WizardsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :cib_writable
  before_filter :cluster_online

  helper_method :workflow_path
  helper_method :workflows

  def index
    @wizards = Wizard.all

    respond_to do |format|
      format.html
    end
  end

  def show
    @wizard = Wizard.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  def create
    @wizard = Wizard.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  protected

  def default_base_layout
    "withrightbar"
  end

  protected

  def set_title
    @title = _('Use a wizard')
  end

  def set_cib
    @cib = current_cib
  end

  def cib_writable
    begin
      Invoker.instance.cibadmin(
        "--modify",
        "--allow-create",
        "--scope",
        "crm_config",
        "--xml-text",
        "<cluster_property_set id=\"hawk-rw-test\"/>"
      )

      Invoker.instance.cibadmin(
        "--delete",
        "--xml-text",
        "<cluster_property_set id=\"hawk-rw-test\"/>")
    rescue SecurityError
      respond_to do |format|
        format.html do
          redirect_to(
            cib_state_url(cib_id: @cib.id),
            alert: _("Permission denied - you do not have write access to the CIB.")
          )
        end
        format.json do
          render json: {
            error: _("Permission denied - you do not have write access to the CIB.")
          }, status: :unprocessable_entity
        end
      end
    rescue NotFoundError
    rescue RuntimeError
    end
  end

  def cluster_online
    %x[/usr/sbin/crm_mon -s >/dev/null 2>&1]

    if $?.exitstatus == Errno::ENOTCONN::Errno
      respond_to do |format|
        format.html do
          redirect_to(
            cib_state_url(cib_id: @cib.id),
            alert: _("Cluster seems to be offline")
          )
        end
        format.json do
          render json: {
            error: _("Cluster seems to be offline")
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
