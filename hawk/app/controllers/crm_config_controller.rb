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
    @crm_config = @cib.find_crm_config(params[:id])
  end

  def show
    # Strictly, this should give you "not found" if the
    # property set doesn't exist (right now it shows an
    # empty set)
    @crm_config = @cib.find_crm_config(params[:id])
  end

  def update
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
    #
    require 'tempfile.rb'
    f = Tempfile.new 'crm_config_update'
    f << "property $id='#{params[:id]}'"
    params[:props].each do |n, v|
      # TODO(must): escape values
      f << " #{n}='#{v}'" if !v.empty?
    end
    f.close
    @result = %x[/usr/sbin/crm -F configure load update #{f.path}]
    f.unlink
    
    # So we actually need to either go to show (with "updated" message)
    # or go back to edit (with suitable error)
  end

  def destroy
    head :forbidden
  end

end
