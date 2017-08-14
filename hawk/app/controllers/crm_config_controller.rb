# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class CrmConfigController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update]

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if params[:revert]
      return redirect_to edit_cib_crm_config_url(cib_id: @cib.id)
    end

    respond_to do |format|
      if @crm_config.update_attributes(params[:crm_config])
        post_process_for! @crm_config

        format.html do
          flash[:success] = _('Configuration updated successfully')
          redirect_to edit_cib_crm_config_url(cib_id: @cib.id)
        end
        format.json do
          render json: @crm_config, status: :updated
        end
      else
        format.html do
          render action: 'edit'
        end
        format.json do
          render json: @crm_config.errors, status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def set_title
    @title = _('Cluster Configuration')
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @crm_config = CrmConfig.new
  end

  def post_process_for!(record)
  end

  def default_base_layout
    "withrightbar"
  end
end
