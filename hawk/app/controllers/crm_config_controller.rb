class CrmConfigController < ApplicationController
  before_filter :login_required

  layout 'main'
  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id]
  end

  def initialize
    @title = _('Cluster Configuration')
  end

  def index
    # This is not strictly correct (index is meant to be a list
    # of all resources), but it's acceptable for now, as we only
    # support manipulating the default crm_config.
    redirect_to :action => 'show', :id => 'cib-bootstrap-options'
  end

  def create
    head :forbidden
  end

  def new
    head :forbidden
  end

  def edit
    head :forbidden
  end

  def show
    @crm_config = @cib.find_crm_config(params[:id])
  end

  def update
    head :forbidden
  end

  def destroy
    head :forbidden
  end

end
