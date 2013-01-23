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
    @crm_config = @cib.find_crm_config(params[:id])  # RORSCAN_ITL (authz via cibadmin)
  end

  def show
    redirect_to :action => 'edit'
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end

    # Don't let weird IDs through.
    if params[:id].match(/[^a-zA-Z0-9_-]/)
      flash[:error] = _('Invalid property set ID: %{id}') % { :id => params[:id] }
      redirect_to :action => 'edit'
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
    # Really we want to mostly rely on the shell here.  Shame we
    # can't use the shell to remove properties by specifying
    # a null value to "crm configure property ...", or by
    # replacing sections.
    #
    # TODO(must): die if not operating on local CIB
    # TODO(must): die if operating on non-existent property set
    # TODO(should): if the user deletes all the properties, this
    #               may leave an empty property set lying around.
    #               should "crm configure delete" it, but it
    #               might be a bit unsafe.
    #

    current_config = @cib.find_crm_config(params[:id])  # RORSCAN_ITL (authz via cibadmin)

    # Want to delete properties that currently exist, aren't readonly
    # or advanced (invisible in editor), and aren't in the list of
    # properties the user has just set in the edit form.  Note: this
    # (obviously) must complement the constraints in the edit form!
    props_to_delete = current_config.props.keys.select {|p|
      current_config.all_props[p] && !current_config.all_props[p][:readonly] &&
        (!params[:props] || !params[:props].has_key?(p))
        # (the above line means: no properties passed in, *or* the
        # properties passed in don't include this property)
    }

    rd_to_delete = current_config.rsc_defaults.keys.select {|p|
      current_config.all_rsc_defaults[p] && !current_config.all_rsc_defaults[p][:readonly] &&
        (!params[:rsc_defaults] || !params[:rsc_defaults].has_key?(p))
    }

    od_to_delete = current_config.op_defaults.keys.select {|p|
      current_config.all_op_defaults[p] && !current_config.all_op_defaults[p][:readonly] &&
        (!params[:op_defaults] || !params[:op_defaults].has_key?(p))
    }

    # TODO(must): the above two blocks use a mix of string and symbol
    # hash keys.  This is wildly confusing.  Must deconfustificate this.

    cmd = "property $id='#{params[:id]}'"
    params[:props].each do |n, v|
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
    end if params[:props]
    
    cmd += "\nrsc_defaults $id='rsc-options'"
    params[:rsc_defaults].each do |n, v|
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
    end if params[:rsc_defaults]

    cmd += "\nop_defaults $id='op-options'"
    params[:op_defaults].each do |n, v|
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
    end if params[:op_defaults]

    result = Invoker.instance.crm_configure_load_update cmd

    if result == true
      props_to_delete.each do |p|
        # TODO(must): does not report errors!
        Util.run_as(current_user, 'crm_attribute', '--attr-name', p.to_s, '--delete-attr')
      end
      rd_to_delete.each do |p|
        Util.run_as(current_user, 'crm_attribute', '--type', 'rsc_defaults', '--attr-name', p, '--delete-attr')
      end
      od_to_delete.each do |p|
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

  # TODO(must): this really does not belong here.  All the static crm_config
  # info belongs well outside this class, and should be generically accessible,
  # once, without loading the cib or finding a given crm_config instance.
  # When this is fixed, config/routes.rb needs to be changed to match, as
  # does crm_config/edit.html.erb.
  def info
    # RORSCAN_INL (authz via cibadmin)
    c = @cib.find_crm_config(params[:id])
    render :json => {
      :props => c.all_props,
      :rsc_defaults => c.all_rsc_defaults,
      :op_defaults => c.all_op_defaults
    }
  end

end
