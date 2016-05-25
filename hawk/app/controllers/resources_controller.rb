# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ResourcesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Resource.all.to_json
      end
    end
  end

  def status
    result = [].tap do |result|
      selected = []

      Resource.all.each do |resource|
        case resource.object_type
        when "group"
          resource.children.map! do |child|
            r = Resource.find(child)

            selected.push r.id
            r
          end

          result.push resource
        when "clone", "master"
          r = Resource.find(resource.child)

          selected.push r.id
          resource.child = r

          result.push resource
        when "tag"
          resource.refs.map! do |child|
            begin
              Resource.find(child)
            rescue Cib::RecordNotFound
              next
            end
          end.reject! { |e| e.nil? }

          result.push resource
        end
      end

      result.push Primitive.all.reject { |resource|
        selected.include? resource.id
      }
    end.flatten

    respond_to do |format|
      format.json do
        render json: result.to_json
      end
    end
  end

  def types
    respond_to do |format|
      format.html
    end
  end

  def show
    @resource = Resource.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  def events
    @resource = Resource.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  def start
    @resource = Resource.find params[:id]
    run_resource_action @resource.start!,
                        _("Successfully started the resource"),
                        _("Failed to start the resource: %{err}")
  end

  def stop
    @resource = Resource.find params[:id]
    run_resource_action @resource.stop!,
                        _("Successfully stopped the resource"),
                        _("Failed to stop the resource: %{err}")
  end

  def promote
    @resource = Resource.find params[:id]
    run_resource_action @resource.promote!,
                        _("Successfully promoted the resource"),
                        _("Failed to promote the resource: %{err}")
  end

  def demote
    @resource = Resource.find params[:id]
    run_resource_action @resource.demote!,
                        _("Successfully demoted the resource"),
                        _("Failed to demote the resource: %{err}")
  end

  def maintenance_on
    @resource = Resource.find params[:id]
    run_resource_action @resource.maintenance!("on"),
                        _("Successfully set the resource in maintenance mode"),
                        _("Failed to set the resource in maintenance mode: %{err}")
  end

  def maintenance_off
    @resource = Resource.find params[:id]
    run_resource_action @resource.maintenance!("off"),
                        _("Successfully disabled maintenance mode for resource"),
                        _("Failed to disable maintenance mode for resource: %{err}")
  end

  def unmigrate
    @resource = Resource.find params[:id]
    run_resource_action @resource.unmigrate!,
                        _("Successfully unmigrated the resource"),
                        _("Failed to unmigrate the resource: %{err}")
  end

  def migrate
    @resource = Resource.find params[:id]
    run_resource_action @resource.migrate!(params[:node]),
                        _("Successfully migrated the resource"),
                        _("Failed to migrate the resource: %{err}")
  end

  def cleanup
    @resource = Resource.find params[:id]
    run_resource_action @resource.cleanup!(params[:node]),
                        _("Successfully cleaned the resource"),
                        _("Failed to clean up the resource: %{err}")
  end

  def rename
    from = params[:id]
    to = params[:to]
    @source = params[:source] || "edit"
    @resource = Resource.find from

    if to.nil?
      respond_to do |format|
        format.html
      end
    else
      _out, err, rc = Invoker.instance.crm_configure("rename #{from} #{to}")

      respond_to do |format|
        if rc == 0
          msg = _("Successfully renamed %{A} to %{B}") % { A: from, B: to }
          format.html do
            flash[:success] = msg
            redirect_to edit_cib_resource_url(cib_id: @cib.id, id: to)
          end
          format.json do
            render json: { success: true, message: msg }
          end
        else
          msg = _("Failed to rename %{A} to %{B}: %{E}") % { A: from, B: to, E: err }
          format.html do
            flash[:danger] = msg

            if @source == "resource"
              redirect_to edit_cib_resource_url(cib_id: @cib.id, id: from)
            else
              redirect_to edit_cib_config_url(cib_id: @cib.id)
            end
          end
          format.json do
            render json: {
              error: msg
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end

  def new
    # redirect depending on type of resource
    resource = Resource.find params[:id]
    new_url = "new_cib_#{resource.object_type}_url".to_sym
    redirect_to send(new_url, cib_id: @cib.id, id: params[:id])
  end

  def edit
    # redirect depending on type of resource
    resource = Resource.find params[:id]
    edit_url = "edit_cib_#{resource.object_type}_url".to_sym
    redirect_to send(edit_url, cib_id: @cib.id, id: params[:id])
  end

  protected

  def set_title
    @title = _("Resources")
  end

  def set_cib
    @cib = current_cib
  end

  def default_base_layout
    if ["index", "types"].include? params[:action]
      "withrightbar"
    elsif params[:action] == "show" || params[:action] == "events" || params[:action] == "rename"
      "modal"
    else
      super
    end
  end

  def run_resource_action(result, success, error)
    _out, err, rc = result

    respond_to do |format|
      if rc == 0
        format.json do
          render json: {
            success: true,
            message: success
          }
        end
      else
        format.json do
          render json: {
            error: error % { err: err }
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
