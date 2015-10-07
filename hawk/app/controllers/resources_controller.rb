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
        render json: Resource.all.reject { |resource|
          resource.object_type == "template"
        }.to_json
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
        when "clone"
        when "master"
          r = Resource.find(resource.child)

          selected.push r.id
          resource.child = r

          result.push resource
        when "tag"
          resource.refs.map! do |child|
            Resource.find(child)
          end

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

  def manage
    @resource = Resource.find params[:id]
    run_resource_action @resource.manage!,
                        _("Successfully set the resource in managed mode"),
                        _("Failed to set the resource in managed mode: %{err}")
  end

  def unmanage
    @resource = Resource.find params[:id]
    run_resource_action @resource.unmanage!,
                        _("Successfully set the resource in unmanaged mode"),
                        _("Failed to set the resource in unmanaged mode: %{err}")
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
    else
      if params[:action] == "show"
        "modal"
      else
        super
      end
    end
  end

  def run_resource_action(result, success, error)
    out, err, rc = result

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
