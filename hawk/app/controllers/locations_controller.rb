# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class LocationsController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Location.ordered.to_json
      end
    end
  end

  def new
    @title = _('Create Location Constraint')
    @location = Location.new

    if @location.rules.empty?
      @location.rules.push(
        score: "INFINITY",
        role: "",
        operator: "and",
        expressions: []
      )
    end

    respond_to do |format|
      format.html
    end
  end

  class CreateFailure < RuntimeError
  end

  def create
    normalize_params! params[:location].permit!
    @title = _('Create Location Constraint')

    @location = Location.new params[:location].permit!

    if @location.rules.empty?
      @location.rules.push(
        score: "INFINITY",
        role: "",
        operator: "and",
        expressions: []
      )
    end
    @location.rules = Util.map_value(@location.rules)

    fail CreateFailure, @location.errors.full_messages.to_sentence unless @location.save
    post_process_for! @location

    respond_to do |format|
      format.html do
        flash[:success] = _('Constraint created successfully')
        redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
      end
      format.json do
        render json: @location, status: :created
      end
    end

  rescue CreateFailure => e
    respond_to do |format|
      format.html do
        flash[:danger] = e.to_s
        render action: "new"
      end
      format.json do
        render json: @location.errors, status: :unprocessable_entity
      end
    end
  end

  def edit
    @title = _('Edit Location Constraint')

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:location].permit!
    @title = _('Edit Location Constraint')

    if params[:revert]
      return redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
    end

    respond_to do |format|
      if @location.update_attributes(params[:location].permit!)
        post_process_for! @location

        format.html do
          flash[:success] = _('Constraint updated successfully')
          redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
        end
        format.json do
          render json: @location, status: :updated
        end
      else
        format.html do
          render action: 'edit'
        end
        format.json do
          render json: @location.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm('--force', 'configure', 'delete', @location.id)
      if rc == 0
        format.html do
          flash[:success] = _('Location deleted successfully')
          flash[:warning] = err unless err.blank?
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Location deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _('Error deleting %s: %s') % [@location.id, err]
          redirect_to edit_cib_location_url(cib_id: @cib.id, id: @location.id)
        end
        format.json do
          render json: { error: _('Error deleting %s: %s') % [@location.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @location.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _('Location Constraints')
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @location = Location.find params[:id]

    unless @location
      respond_to do |format|
        format.html do
          flash[:alert] = _('The location constraint does not exist')
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(_record)
  end

  def normalize_params!(current)
    if current[:rules].nil?
      current[:rules] = []
    else
      current[:rules] = current[:rules].values
    end

    current[:rules].each_with_index do |_, index|
      if current[:rules][index][:expressions]
        current[:rules][index][:expressions] = current[:rules][index][:expressions].values
      else
        current[:rules][index][:expressions] = []
      end
    end
  end

  def default_base_layout
    "withrightbar"
  end
end
