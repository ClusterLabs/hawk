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
    result = @resource.start!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully started the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to start the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def stop
    @resource = Resource.find params[:id]
    result = @resource.stop!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully stopped the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to stop the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def promote
    @resource = Resource.find params[:id]
    result = @resource.promote!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully promoted the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to promote the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def demote
    @resource = Resource.find params[:id]
    result = @resource.demote!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully demoted the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to demote the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def manage
    @resource = Resource.find params[:id]
    result = @resource.manage!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully managed the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to manage the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def unmanage
    @resource = Resource.find params[:id]
    result = @resource.unmanage!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully unmanaged the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to unmanage the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def unmigrate
    @resource = Resource.find params[:id]
    result = @resource.unmigrate!

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully unmigrated the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to unmigrate the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def migrate
    @resource = Resource.find params[:id]
    result = @resource.migrate! params[:node]

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully migrated the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to migrate the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def cleanup
    @resource = Resource.find params[:id]
    result = @resource.cleanup! params[:node]

    respond_to do |format|
      if result == true
        format.json do
          render json: {
            success: true,
            message: _("Successfully cleaned the resource")
          }
        end
      else
        format.json do
          render json: {
            error: _("Failed to cleanup the resource: %{err}", err: result[0])
          }, status: :unprocessable_entity
        end
      end
    end
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
end
