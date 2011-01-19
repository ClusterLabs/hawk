#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2010 Novell Inc., Tim Serong <tserong@novell.com>
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

class CrmConfigController < ApplicationController
  before_filter :login_required

  layout 'main'
  before_filter :get_cib    # TODO(should): only do this when absolutely necessary, e.g.: edit but not update

  def get_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def initialize
    super
    @title = _('Cluster Configuration')
  end

  def index
    # This is not strictly correct (index is meant to be a list
    # of all resources), but it's acceptable for now, as we only
    # support manipulating the default crm_config.
    redirect_to :action => 'edit', :id => 'cib-bootstrap-options'
  end

  def create
    head :forbidden
  end

  def new
    head :forbidden
  end

  def edit
    # Strictly, this should give you "not found" if the
    # property set doesn't exist (right now it shows an
    # empty set)
    @crm_config = @cib.find_crm_config(params[:id])
  end

  def show
    redirect_to :action => 'edit'
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end
    unless params[:cancel].blank?
      redirect_to status_path
      return
    end

    #
    # This is (logically) a replace of the entire contents
    # of the existing property set with whatever is submitted.
    # There are a couple of gotchas:
    #  - Need to not overwrite R/O properties (dc-version)
    #  - Can't just replace the whole XML chunk, there might
    #    be rules and scores and things we don't understand,
    #    so really we need to do a merge of nvpairs.
    # Really we can mostly rely on the shell here.  Shame we
    # can't use the shell to remove properties by specifying
    # a null value to "crm configure property ..."
    #
    # TODO(must): die if not operating on local CIB
    # TODO(must): die if operating on non-existent property set
    # TODO(should): if the user deletes all the properties, this
    #               leaves an empty property set lying around.
    #               should "crm configure delete" it, but it
    #               might be a bit unsafe.
    #
    require 'tempfile.rb'
    f = Tempfile.new 'crm_config_update'
    f << "property $id='#{params[:id]}'"
    params[:props].each do |n, v|
      # TODO(must): escape values (and ID above, for that matter)
      f << " #{n}='#{v}'" if !v.empty?
    end if params[:props]
    f.close
    # Evil to allow unprivileged user running crm shell to read the file
    # TODO(should): can we just allow group (probably ok live, but no
    # good for testing when running as root), or some other alternative
    # with piping data to crm?
    File.chmod(0666, f.path)
    %x[/bin/cp #{f.path} /tmp/foo]
    # TODO(should): consolidate with MainController::invoke
    # TODO(must): crm lies about failed update when run with R/O access!
    stdin, stdout, stderr, thread = Util.run_as(current_user, 'crm', '-F', 'configure', 'load', 'update', f.path)
    stdin.close
    stdout.close
    @result = stderr.read()
    stderr.close
    f.unlink
    
    if thread.value.exitstatus == 0
      flash[:highlight] = _('Your changes have been saved')
    else
      flash[:error] = _('Unable to apply changes: %{msg}') % { :msg => @result }
    end

    redirect_to :action => 'edit'
  end

  def destroy
    head :forbidden
  end

  # TODO(must): this really does not belong here.  All the static crm_config
  # info belongs well outside this class, and should be generically accessible,
  # once, without loading the cib or finding a given crm_config instance.
  # When this is fixed, config/routes.rb needs to be changed to match, as
  # does crm_config/edit.html.erb.
  def info
    render :json => @cib.find_crm_config(params[:id]).all_types
  end

end
