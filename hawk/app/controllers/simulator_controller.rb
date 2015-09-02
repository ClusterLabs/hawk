# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class SimulatorController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def reset
    respond_to do |format|
      format.json do
        head :bad_request
      end
    end
  end

  def run
    respond_to do |format|
      format.json do
        head :bad_request
      end
    end
  end

  # Bit of a hack, used only by simulator to get valid intervals
  # for the monitor op in milliseconds.  Returns an array of
  # possible intervals (zero elements if no monitor op defined,
  # one element in the general case, but should be two for m/s
  # resources, or more if there's depths etc.).
  def intervals
    intervals = []
    res = Primitive.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
    Rails.logger.debug "#{res.ops}"
    res.ops["monitor"].each do |op|
      Rails.logger.debug "#{params[:id]}, #{op}"
      intervals << Util.crm_get_msec(op["interval"])
    end if res.ops.has_key?("monitor")
    render :json => intervals
  end

  protected

  def set_title
    @title = _("Simulator")
  end

  def set_cib
    @cib = current_cib
  end
end
