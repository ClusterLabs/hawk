#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2010-1013 Novell Inc., All Rights Reserved.
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

class CrmConfigController < ApplicationController
  before_filter :login_required

  layout 'main'
  # Need cib for both edit and update (but ultimateyl want to minimize the amount of processing...)
  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id], current_user # RORSCAN_ITL (not mass assignment)
  end

  def initialize
    super
    @title = _('Cluster Configuration')
  end

  def index
    # This is not strictly correct (index is meant to be a list
    # of all resources), but it's acceptable for now, as we only
    # support manipulating the default crm_config.
    redirect_to :action => 'edit'
  end

  def create
    head :forbidden
  end

  def new
    head :forbidden
  end

  def edit
    @crm_config = CrmConfig.new
  end

  def show
    redirect_to :action => 'edit'
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end

    @crm_config = CrmConfig.new

    # Note: all this really belongs in the model...

    #
    # This is (logically) a replace of the entire contents
    # of the existing property set with whatever is submitted.
    # There are a couple of gotchas:
    #  - Need to not overwrite R/O properties (dc-version)
    #  - Can't just replace the whole XML chunk, there might
    #    be rules and scores and things we don't understand,
    #    so really we need to do a merge of nvpairs.
    # Really we want to mostly rely on the shell here.  Shame we
    # can't use the shell to remove properties by specifying
    # a null value to "crm configure property ...", or by
    # replacing sections.
    #
    # TODO(should): if the user deletes all the properties, this
    #               may leave an empty property set lying around.
    #               should "crm configure delete" it, but it
    #               might be a bit unsafe.
    #

    # Want to delete properties that currently exist, aren't readonly
    # or advanced (invisible in editor), and aren't in the list of
    # properties the user has just set in the edit form.  Note: this
    # (obviously) must complement the constraints in the edit form!
    crm_config_to_delete = to_delete("crm_config")
    rsc_defaults_to_delete = to_delete("rsc_defaults")
    op_defaults_to_delete = to_delete("op_defaults")

    cmd =
      "property $id='cib-bootstrap-options'" + crm_script("crm_config") + "\n" +
      "rsc_defaults $id='rsc-options'"      + crm_script("rsc_defaults") + "\n" +
      "op_defaults $id='op-options'"        + crm_script("op_defaults")

    result = Invoker.instance.crm_configure_load_update cmd

    if result == true
      # TODO(must): does not report errors!
      # TODO(should): consolidate once bnc#800071 is fixed
      crm_config_to_delete.each do |p|
        Util.run_as(current_user, 'crm_attribute', '--attr-name', p.to_s, '--delete-attr')
      end
      rsc_defaults_to_delete.each do |p|
        Util.run_as(current_user, 'crm_attribute', '--type', 'rsc_defaults', '--attr-name', p, '--delete-attr')
      end
      op_defaults_to_delete.each do |p|
        Util.run_as(current_user, 'crm_attribute', '--type', 'op_defaults', '--attr-name', p, '--delete-attr')
      end
      flash[:highlight] = _('Your changes have been saved')
    else
      flash[:error] = _('Unable to apply changes: %{msg}') % { :msg => result }
    end

    redirect_to :action => 'edit'
  end

  def destroy
    head :forbidden
  end

  private

  def to_delete(set)
    # Want to delete properties that currently exist, aren't readonly
    # or advanced (invisible in editor), and aren't in the list of
    # properties the user has just set in the edit form.  Note: this
    # (obviously) must complement the constraints in the edit form!
    @crm_config.props[set].keys.select {|p|
      @crm_config.all_props[set][p] && !@crm_config.all_props[set][p][:readonly] &&
        (!params[set.to_sym] || !params[set.to_sym].has_key?(p))
        # (the above line means: no properties passed in, *or* the
        # properties passed in don't include this property)
    }
  end

  def crm_script(set)
    cmd = ""
    params[set.to_sym].each do |n, v|
      next if v.empty?
      sq = v.index("'")
      dq = v.index('"')
      if sq && dq
        flash[:error] = _("Can't set property %{p}, because the value contains both single and double quotes") % { :p => n }
      elsif sq
        cmd += " #{n}=\"#{v}\""
      else
        cmd += " #{n}='#{v}'"
      end
    end if params[set.to_sym]
    cmd
  end

end
