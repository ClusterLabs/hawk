#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2010 Novell Inc., Tim Serong <tserong@novell.com>
#                        All Rights Reserved.
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

require 'natcmp'
require 'util'
require 'rexml/document' unless defined? REXML::Document

class MainController < ApplicationController
  before_filter :login_required

  private

  # Invoke some command, returning OK or JSON error as appropriate
  def invoke(*cmd)
    stdin, stdout, stderr = Util.popen3(*cmd)
    if $?.exitstatus == 0
      head :ok
    else
      render :status => 500, :json => {
        :error  => _('%{cmd} failed (status: %{status})') % { :cmd => cmd.join(' '), :status => $?.exitstatus },
        :stderr => stderr.readlines
      }
    end
  end

  public

  def initialize
    require 'socket'
    @host = Socket.gethostname  # should be short hostname
  end

  # Render cluster status by default
  # (can't just render :action => 'status',
  # or we don't get the instance variables)
  def index
    redirect_to :action => 'status'
  end

  def gettext
    render :partial => 'gettext'
  end

  def status
    @title = _('Cluster Status')
  end

  # standby/online (op validity guaranteed by routes)
  def node_standby
    if params[:node]
      invoke '/usr/sbin/crm_standby', '-N', params[:node], '-v', params[:op] == 'standby' ? 'on' : 'off'
    else
      render :status => 400, :json => {
        :error => _('Required parameter "node" not specified')
      }
    end
  end

  def node_fence
    if params[:node]
      invoke '/usr/sbin/crm_attribute', '-t', 'status', '-U', params[:node], '-n', 'terminate', '-v', 'true'
    else
      render :status => 400, :json => {
        :error => _('Required parameter "node" not specified')
      }
    end
  end

#  def node_mark
#    head :ok
#  end

  # start, stop, etc. (op validity guaranteed by routes)
  # TODO(should): exceptions to handle missing params
  def resource_op
    if params[:resource]
      invoke '/usr/sbin/crm', 'resource', params[:op], params[:resource]
    else
      render :status => 400, :json => {
        :error => _('Required parameter "resource" not specified')
      }
    end
  end

  def resource_migrate
    if params[:resource] && params[:node]
      invoke '/usr/sbin/crm', 'resource', 'migrate', params[:resource], params[:node]
    else
      render :status => 400, :json => {
        :error => _('Required parameters "resource" and "node" not specified')
      }
    end
  end

end
