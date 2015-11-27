# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class StatesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def show
    respond_to do |format|
      format.html
      format.json do
        redirect_to cib_path(cib_id: current_cib.id, format: "json", mini: params[:mini])
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
end
