# Copyright (c) 2016 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

class FencingController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def index
    @fencing_topology = current_cib.fencing_topology
    respond_to do |format|
      format.html
      format.json do
        render json: @fencing_topology.to_json
      end
    end
  end

  def edit
    if request.post?
      fencing = params[:fencing]
      fencing = fencing["fencing"] if fencing.is_a? Hash
      fencing = [] if fencing.nil?
      n = -1

      # convert to xml
      txt = "<fencing-topology>"
      fencing.each do |level|
        id_ = "fencing" if n < 0
        id_ = "fencing-#{n}" unless n < 0
        id_ = id_.encode(xml: :attr)
        n += 1
        tgt = level["target"].encode(xml: :attr)
        idx = level["index"].to_s.encode(xml: :attr)
        devs = level["devices"].join(",").encode(xml: :attr)
        if level["type"] == "node"
          txt += "<fencing-level devices=#{devs} index=#{idx} target=#{tgt} id=#{id_} />"
        elsif level["type"] == "pattern"
          txt += "<fencing-level devices=#{devs} index=#{idx} target-pattern=#{tgt} id=#{id_} />"
        else
          val = level["value"].encode(xml: :attr)
          txt += "<fencing-level devices=#{devs} index=#{idx} target-attribute=#{tgt} target-value=#{val} id=#{id_} />"
        end
      end
      txt += "</fencing-topology>"
      begin
        Invoker.instance.cibadmin_modify '<cib><configuration><fencing-topology/></configuration></cib>' if current_cib.fencing_topology.length == 0
        Invoker.instance.cibadmin_replace_xpath "/cib/configuration/fencing-topology", txt
        respond_to do |format|
          format.html do
            flash[:success] = _("Fencing topology updated successfully")
            redirect_to cib_fencing_path(cib_id: current_cib.id)
          end
          format.json do
            render json: {
              success: true,
              message: _("Fencing topology updated successfully")
            }
          end
        end
      rescue RuntimeError => err
        Rails.logger.debug "cibadmin error: #{err}"
        respond_to do |format|
          format.html do
            flash[:alert] = _('Failed to edit fencing topology: %{msg}') % { msg: err }
            redirect_to cib_fencing_edit_path(cib_id: current_cib.id)
          end
          format.json do
            render json: { error: _('Failed to edit fencing topology: %{msg}') % { msg: err } }, status: :unprocessable_entity
          end
        end
      end
    else
      @title = _("Edit Fencing Topology")
      @fencing_topology = current_cib.fencing_topology

      respond_to do |format|
        format.html
      end
    end
  end

  protected

  def set_title
    @title = _("Fencing Topology")
  end

  def set_cib
    @cib = current_cib
  end

  def default_base_layout
    "withrightbar"
  end
end
