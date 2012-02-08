#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2011 Novell Inc., Tim Serong <tserong@novell.com>
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

class OrdersController < ApplicationController
  before_filter :login_required

  layout 'main'
  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id], current_user # RORSCAN_ITL (not mass assignment)
  end

  def initialize
    super
    @title = _('Edit Order Constraint')
  end

  def new
    @title = _('Create Order Constraint')
    @ord = Order.new
  end

  def create
    @title = _('Create Order Constraint')
    unless params[:cancel].blank?
      redirect_to cib_constraints_path
      return
    end
    params[:order][:symmetrical] = params[:order][:symmetrical] == "true" ? true : false
    normalize_resources!(params[:order])
    @ord = Order.new params[:order]  # RORSCAN_ITL (mass ass. OK)
    if @ord.save
      flash[:highlight] = _('Constraint created successfully')
      redirect_to :action => 'edit', :id => @ord.id
    else
      render :action => 'new'
    end
  end

  def edit
    @ord = Order.find params[:id]
  end

  def update
    unless params[:revert].blank?
      redirect_to :action => 'edit'
      return
    end
    unless params[:cancel].blank?
      redirect_to cib_constraints_path
      return
    end
    @ord = Order.find params[:id]
    params[:order][:symmetrical] = params[:order][:symmetrical] == "true" ? true : false
    normalize_resources!(params[:order])
    if @ord.update_attributes(params[:order])  # RORSCAN_ITL (mass ass. OK)
      flash[:highlight] = _('Constraint updated successfully')
      redirect_to :action => 'edit', :id => @ord.id
    else
      render :action => 'edit'
    end
  end

  private

  # Pass params[:order], to map from form-style:
  #  [
  #    {"action"=>"", "id"=>"foo"},
  #    "rel",
  #    {"action"=>"", "id"=>"bar"},
  #    {"action"=>"", "id"=>"baz"}
  #  ]
  # to model-style:
  #  [
  #    {:resources => [ { :id => 'foo' } ]
  #    {:sequential => false,
  #     :resources => [ { :id => 'foo' }, { :id => 'bar' } ]
  #  ]
  # Note that nonsequential sets will never be collapsed
  # (this is intentional, it's up to the model to collapse
  # these if it wants to).  Note also that incoming actions
  # in sequential sets must already all be the same within
  # a set.
  def normalize_resources!(p)
    m = []
    set = {}
    p[:resources].each do |r|
      if r == 'rel'
        set[:sequential] = set[:resources].length == 1
        m << set
        set = {}
      else
        set[:action] = r[:action] != "" ? r[:action] : nil
        set[:resources] ||= []
        set[:resources] << { :id => r[:id] }
      end
    end
    set[:sequential] = set[:resources].length == 1
    m << set
    p[:resources] = m
  end
end
