# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class OrdersController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib
  before_action :set_record, only: [:edit, :update, :destroy, :show]

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Order.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Order")
    @order = Order.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:order]
    @title = _("Create Order")

    @order = Order.new params[:order]

    respond_to do |format|
      if @order.save
        post_process_for! @order

        format.html do
          flash[:success] = _("Constraint created successfully")
          redirect_to edit_cib_order_url(cib_id: @cib.id, id: @order.id)
        end
        format.json do
          render json: @order, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @order.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Order")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:order]
    @title = _("Edit Order")

    if params[:revert]
      return redirect_to edit_cib_order_url(cib_id: @cib.id, id: @order.id)
    end

    respond_to do |format|
      if @order.update_attributes(params[:order])
        post_process_for! @order

        format.html do
          flash[:success] = _("Constraint updated successfully")
          redirect_to edit_cib_order_url(cib_id: @cib.id, id: @order.id)
        end
        format.json do
          render json: @order, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @order.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @order.id)
      if rc == 0
        format.html do
          flash[:success] = _("Order deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Order deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@order.id, err]
          redirect_to edit_cib_order_url(cib_id: @cib.id, id: @order.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@order.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @order.to_json
      end
      format.any { not_found  }
    end
  end

  protected

  def set_title
    @title = _("Orders")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @order = Order.find params[:id]

    unless @order
      respond_to do |format|
        format.html do
          flash[:alert] = _("The order constraint does not exist")
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
    if params[:order][:resources].nil?
      params[:order][:resources] = []
    else
      params[:order][:resources] = params[:order][:resources].values
    end
  end

  def default_base_layout
    "withrightbar"
  end
end
