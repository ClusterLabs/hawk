# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class CibController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_cib

  skip_before_action :verify_authenticity_token, only: [:show, :apply]

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: current_cib.status()
      end
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :not_found
      end
      format.any { head :not_found }
    end
  rescue SecurityError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :forbidden
      end
      format.any { head :forbidden }
    end
  rescue RuntimeError => e
    respond_to do |format|
      format.json do
        render json: { errors: [e.message] }, status: :internal_server_error
      end
      format.any { head :internal_server_error }
    end
  end

  def apply
    if request.post?
      out, err, rc = Invoker.instance.crm_configure("cib commit #{current_cib.id}")
      if rc != 0
        Rails.logger.debug "apply fail: #{err}, #{current_cib.id}"
        flash[:danger] = _("Failed to apply configuration")
        redirect_to cib_path(cib_id: current_cib.id)
        return
      end
      Rails.logger.debug "apply OK: #{out}"
      flash[:success] = _("Applied configuration successfully")
      redirect_to cib_path(cib_id: :live)
    else
      render
    end
  end

  def options
    respond_to do |format|
      format.json do
        render json: {}, status: 200
      end
    end
  end

  def ops
    invars = params[:id].split(",", 2)
    if invars.length == 1
      rsc = invars[0]
      node = "*"
    else
      rsc, node = invars
      if node
        current_cib.nodes.each do |n|
          node = n[:uname] if n[:id].to_s == node && n[:uname]
        end
      end
    end
    ops = [].tap do |ret|
      Util.safe_x("/usr/sbin/crm_resource", "-o").each_line do |line|
        m = /(\S+)\s*\(([^\)]+)\):\s*([^:]+):\s*(\S+)\s*\(([^)]+)\):\s*(\S+)/.match(line)
        if m
          op = {
            resource: m[1],
            agent: m[2].gsub(/::/, ":"),
            state: m[3].downcase,
            op: m[4],
            complete: m[6]
          }
          m[5].split(', ').each do |attr|
            kv = attr.split('=', 2)
            op[kv[0].underscore.to_sym] = kv[1] if kv.length > 1
          end
          ret << op
        end
      end
    end
    ops = ops.select { |r| related(rsc).include? r[:resource] } if rsc != "*"
    ops = ops.select { |r| r[:node] == node } if node != "*"
    respond_to do |format|
      format.json do
        render json: ops.to_json
      end
    end
  end

  protected

  def set_title
    @title = _("Status")
  end

  def set_cib
    @cib = current_cib
  end

  def related(rsc)
    info = current_cib.resources_by_id[rsc]
    return [rsc] if info.nil?
    [].tap do |ret|
      ret.push rsc
      info[:children].each do |child|
        ret.concat related(child[:id])
      end unless info[:children].nil?
    end
  end

  def detect_modal_layout
    if request.xhr? && (params[:action] == :meta || params[:action] == :apply)
      "modal"
    else
      detect_current_layout
    end
  end
end
