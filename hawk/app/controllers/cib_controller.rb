class CibController < ApplicationController
  before_filter :login_required

  def index
    render :json => [ 'live' ]
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
    begin
      cib = Cib.new(params[:id], params[:debug] == 'file')
    rescue ArgumentError
      head :not_found
      return
    rescue RuntimeError => e
      render :json => { :errors => [ e.message ] }
      return
    end
    
    # This blob is remarkably like the CIB, but staus is consolidated into the
    # main sections (nodes, resources) rather than being kept separate.
    render :json => {
      :meta => {
        :epoch    => cib.epoch,
        :dc       => cib.dc
      },
      :errors     => cib.errors,
      :crm_config => cib.crm_config,
      :nodes      => cib.nodes,
      :resources  => cib.resources
      # also constraints, op_defaults, rsc_defaults, ...
    }
  end

  def update
    head :forbidden
  end

  def destroy
    head :forbidden
  end
end
