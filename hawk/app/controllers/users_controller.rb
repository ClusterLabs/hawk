#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2014 SUSE LLC, All Rights Reserved.
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

class UsersController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy]
  before_filter :check_support

  def index
    @users = User.ordered

    respond_to do |format|
      format.html
    end
  end

  def new
    @title = _('Create User')
    @user = User.new

    respond_to do |format|
      format.html
    end
  end

  def create
    @title = _('Create User')
    @user = User.new params[:user]

    respond_to do |format|
      if @user.save
        post_process_for! @user

        format.html do
          flash[:success] = _('User created successfully')
          redirect_to edit_cib_user_url(cib_id: @cib.id, id: @user.id)
        end
      else
        format.html do
          render action: 'new'
        end
      end
    end
  end

  def edit
    @title = _('Edit User')

    respond_to do |format|
      format.html
    end
  end

  def update
    @title = _('Edit User')

    if params[:revert]
      return redirect_to edit_cib_user_url(cib_id: @cib.id, id: @user.id)
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        post_process_for! @user

        format.html do
          flash[:success] = _('User updated successfully')
          redirect_to edit_cib_user_url(cib_id: @cib.id, id: @user.id)
        end
      else
        format.html do
          render action: 'edit'
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if Invoker.instance.crm('--force', 'configure', 'delete', @user.id)
        format.html do
          flash[:success] = _('User deleted successfully')
          redirect_to cib_users_url(cib_id: @cib.id)
        end
      else
        format.html do
          flash[:alert] = _('Error deleting %s') % @user.id
          redirect_to cib_users_url(cib_id: @cib.id)
        end
      end
    end
  end

  protected

  def set_title
    @title = _('Users')
  end

  def set_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def set_record
    @user = User.find params[:id]

    unless @user
      respond_to do |format|
        format.html do
          flash[:alert] = _('The user does not exist')
          redirect_to cib_users_url(cib_id: @cib.id)
        end
      end
    end
  end

  def check_support
    check = Util.safe_x(
      '/usr/sbin/cibadmin',
      '-Ql',
      '--xpath',
      '//configuration//crm_config//nvpair[@name=\'enable-acl\' and @value=\'true\']'.shellescape
    ).chomp.empty?

    if check
      flash.now[:warning] = view_context.link_to(
        _('To enable ACLs, set \'enable-acl\' in the CRM Configuration'),
        edit_cib_crm_config_path(cib_id: @cib.id)
      )
    end

    cibadmin = Util.safe_x(
      '/usr/sbin/cibadmin',
      '-Ql',
      '--xpath',
      '/cib[@validate-with]'
    ).lines.first

    if m = cibadmin.match(/validate-with=\"pacemaker-([0-9.]+)\"/)
      @supported_schema = m.captures[0].to_f >= 2.0
    else
      @supported_schema = false
    end
  end

  def post_process_for!(record)
  end
end
