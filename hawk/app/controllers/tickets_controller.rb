# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class TicketsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib
  before_filter :set_record, only: [:edit, :update, :destroy, :show, :grant, :revoke]

  rescue_from Constraint::CommandError do |e|
    Rails.logger.error e

    respond_to do |format|
      format.json do
        render json: { error: e.message }
      end
      format.html do
        redirect_to cib_tickets_url(cib_id: @cib.id), alert: e.message
      end
    end
  end

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Ticket.ordered.to_json
      end
    end
  end

  def new
    @title = _("Create Ticket")
    @ticket = Ticket.new

    respond_to do |format|
      format.html
    end
  end

  def create
    normalize_params! params[:ticket]
    @title = _("Create Ticket")

    @ticket = Ticket.new params[:ticket]

    respond_to do |format|
      if @ticket.save
        post_process_for! @ticket

        format.html do
          flash[:success] = _("Constraint created successfully")
          redirect_to edit_cib_ticket_url(cib_id: @cib.id, id: @ticket.id)
        end
        format.json do
          render json: @ticket, status: :created
        end
      else
        format.html do
          render action: "new"
        end
        format.json do
          render json: @ticket.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @title = _("Edit Ticket")

    respond_to do |format|
      format.html
    end
  end

  def update
    normalize_params! params[:ticket]
    @title = _("Edit Ticket")

    if params[:revert]
      return redirect_to edit_cib_ticket_url(cib_id: @cib.id, id: @ticket.id)
    end

    respond_to do |format|
      if @ticket.update_attributes(params[:ticket])
        post_process_for! @ticket

        format.html do
          flash[:success] = _("Constraint updated successfully")
          redirect_to edit_cib_ticket_url(cib_id: @cib.id, id: @ticket.id)
        end
        format.json do
          render json: @ticket, status: :updated
        end
      else
        format.html do
          render action: "edit"
        end
        format.json do
          render json: @ticket.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      out, err, rc = Invoker.instance.crm("--force", "configure", "delete", @ticket.id)
      if rc == 0
        format.html do
          flash[:success] = _("Ticket deleted successfully")
          flash[:warning] = err unless err.blank?
          redirect_to cib_tickets_url(cib_id: @cib.id)
        end
        format.json do
          render json: {
            success: true,
            message: _("Ticket deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s: %s") % [@ticket.id, err]
          redirect_to edit_cib_ticket_url(cib_id: @cib.id, id: @ticket.id)
        end
        format.json do
          render json: { error: _("Error deleting %s: %s") % [@ticket.id, err] }, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @ticket.to_json
      end
      format.html
      format.any { not_found  }
    end
  end

  def grant
    @ticket.grant! @cib.booth.me

    respond_to do |format|
      format.html do
        flash[:success] = _("Successfully granted the ticket")
        redirect_to cib_tickets_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Successfully granted the ticket")
        }
      end
    end
  end

  def revoke
    @ticket.revoke! @cib.booth.me

    respond_to do |format|
      format.html do
        flash[:success] = _("Successfully revoked the ticket")
        redirect_to cib_tickets_url(cib_id: @cib.id)
      end
      format.json do
        render json: {
          success: true,
          message: _("Successfully revoked the ticket")
        }
      end
    end
  end

  protected

  def set_title
    @title = _("Tickets")
  end

  def set_cib
    @cib = current_cib
  end

  def set_record
    @ticket = Ticket.find params[:id]

    unless @ticket
      respond_to do |format|
        format.html do
          flash[:alert] = _("The ticket constraint does not exist")
          redirect_to types_cib_constraints_url(cib_id: @cib.id)
        end
      end
    end
  end

  def post_process_for!(record)
  end

  def normalize_params!(current)
    if params[:ticket][:resources].nil?
      params[:ticket][:resources] = []
    else
      params[:ticket][:resources] = params[:ticket][:resources].values
    end
  end

  def default_base_layout
    if ["index", "types"].include? params[:action]
      "withrightbar"
    else
      if params[:action] == "show"
        "modal"
      else
        super
      end
    end
  end
end
