# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class SimulatorController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  # TODO(must): these both need exception handler for invoker runs
  # TODO(must): only one user at a time can run sims (they stomp on each other)
  # TODO(must): can this ever fail?!?
  #Invoker.instance.run("crm_shadow", "-b", "-r", "#{current_cib.id}")
  # TODO(must): above doesn't clear lrm state - is that a bug? so recreating:
  def reset
    respond_to do |format|
      format.json do
        if current_cib.id == "live"
          head :bad_request
        else
          out, err, rc = Invoker.instance.run("crm_shadow", "-b", "-f", "-c", "#{current_cib.id}")
          if rc == 0
            render json: { success: true }
          else
            render json: { output: out, error: err, status: rc }, status: 500
          end
        end
      end
    end
  end

  def run
    if current_cib.id == "live"
      head :bad_request
      return
    end

    # always reset status before run (so we effectively run from current
    # state of cluster, not state as saved back to shadow cib)
    sim_reload_state

    # TODO(must): sanitize input a bit
    injections = []
    params[:injections].each do |i|
      parts = i.split(/\s+/)
      case parts[0]
      when "node"
        case parts[2]
        when "online"
          injections << "-u" << parts[1]
        when "offline"
          injections << "-d" << parts[1]
        when "unclean"
          injections << "-f" << parts[1]
        end
      when "op"
        # we have something like:
        #  "op monitor:0 stonith-sbd success node-0"
        parts[1].sub!(":", "_")
        injections << "-i" << "#{parts[2]}_#{parts[1]}@#{parts[4]}=#{parts[3]}"
      when "ticket"
        # TODO(could): Warn if feature doesn't exist (or don't show ticket button in UI at all)
        if Util.has_feature?(:sim_ticket)
          case parts[2]
          when "grant"
            injections << "-g" << parts[1]
          when "revoke"
            injections << "-r" << parts[1]
          when "standby"
            injections << "-b" << parts[1]
          when "activate"
            injections << "-e" << parts[1]
          end
        end
      end
    end if params[:injections]
    f = File.new("#{Rails.root}/tmp/sim.info", "w")
    # "live", but will be against shadow CIB
    out, err, status = Invoker.instance.crm_simulate(
                "-S", "-L",
                "-G", "#{Rails.root}/tmp/sim.graph",
                "-D", "#{Rails.root}/tmp/sim.dot",
                *injections)
    if status != 0
      render :json => { error: err }, :status => 500
      return
    end
    f.write(out)
    f.close
    is_empty = true
    begin
      f = File.open("#{Rails.root}/tmp/sim.graph")
      if f.readline().match(/^<transition_graph.*[^\/]>$/)
        # Cheap test - if the first line is a non-closed transition_graph element,
        # we know it's not an empty graph.
        is_empty = false
      end
      f.close
    rescue Exception
      # TODO(could): actually handle potential failure of crm_simulate run
      render json: { error: "Could not read graph" }, status: 500
    end
    render json: { :is_empty => is_empty }
  end

  # TODO(must): make sure dot is installed
  def result
    case params[:file]
    when "info"
      send_data File.new("#{Rails.root}/tmp/sim.info").read,
                type: "text/plain", disposition: :inline
    when "in"
      shadow_id = ENV["CIB_shadow"]
      ENV.delete("CIB_shadow")
      send_data Invoker.instance.cibadmin('-Ql'), type: (params[:munge] == "txt" ? "text/plain" : "text/xml"), disposition: :inline
      ENV["CIB_shadow"] = shadow_id
    when "out"
      send_data Invoker.instance.cibadmin('-Ql'), type: (params[:munge] == "txt" ? "text/plain" : "text/xml"), disposition: :inline
    when "graph-xml"
      send_data File.new("#{Rails.root}/tmp/sim.graph").read, type: (params[:munge] == "txt" ? "text/plain" : "text/xml"), disposition: :inline
    when "graph"
      svg, err, status = Util.capture3("/usr/bin/dot", "-Tsvg", "#{Rails.root}/tmp/sim.dot")
      if status != 0
        render json: { error: err }, status: 500
      else
        send_data svg, type: :svg, disposition: :inline
      end
    else
      head :not_found
    end
  end

  # Bit of a hack, used only by simulator to get valid intervals
  # for the monitor op in milliseconds.  Returns an array of
  # possible intervals (zero elements if no monitor op defined,
  # one element in the general case, but should be two for m/s
  # resources, or more if there's depths etc.).
  def intervals
    intervals = []
    res = Primitive.find params[:id]  # RORSCAN_ITL (authz via cibadmin)
    Rails.logger.debug "#{res.ops}"
    res.ops["monitor"].each do |op|
      Rails.logger.debug "#{params[:id]}, #{op}"
      intervals << Util.crm_get_msec(op["interval"])
    end if res.ops.has_key?("monitor")
    render json: intervals
  end

  protected

  def set_title
    @title = _("Simulator")
  end

  def set_cib
    @cib = current_cib
  end

  def sim_reload_state
    require "tempfile"
    shadow_id = ENV["CIB_shadow"]
    ENV.delete("CIB_shadow")
    begin
      tmpfile = Tempfile.new("cib_state")
      tmpfile.write(Invoker.instance.cibadmin('-Ql', '--xpath', '//status'))
      tmpfile.close
      File.chmod(0666, tmpfile.path)
      ENV["CIB_shadow"] = shadow_id
      # TODO(must): Handle error here
      Rails.logger.debug("CIB_shadow: #{shadow_id}")
      Invoker.instance.cibadmin('--replace', '--xml-file', tmpfile.path)
    ensure
      tmpfile.unlink
    end
  end

end
