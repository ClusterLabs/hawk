class CrmConfigController < ApplicationController
  before_filter :login_required

  layout 'main'
  before_filter :get_cib

  def get_cib
    @cib = Cib.new params[:cib_id], current_user
  end

  def initialize
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
    @result = %x[/usr/sbin/crm -F configure load update #{f.path} 2>&1]
    f.unlink
    
    if $?.exitstatus == 0
      flash[:highlight] = _('Your changes have been saved')
    else
      flash[:error] = _('Unable to apply changes: %{msg}') % { :msg => @result }
    end

    redirect_to :action => 'edit'
  end

  def destroy
    head :forbidden
  end

end
