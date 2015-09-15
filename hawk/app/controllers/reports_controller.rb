# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ReportsController < ApplicationController
  before_filter :login_required
  before_filter :god_required
  before_filter :set_title
  before_filter :set_record, only: [:destroy, :download]
  before_filter :set_transition, only: [:show, :detail, :graph, :logs, :diff]

  helper_method :current_transition
  helper_method :prev_transition
  helper_method :next_transition
  helper_method :first_transition
  helper_method :last_transition
  helper_method :window_transition

  def index
    @hb_report = HbReport.new

    respond_to do |format|
      format.html
      format.json do
        render json: Report.all
      end
    end
  end

  def generate
    errors = []
    begin
      from_time = DateTime.parse(params[:report][:from_time]).iso8601()
    rescue Exception => e
      errors << _("from_time must be a valid datetime")
    end
    begin
      to_time = DateTime.parse(params[:report][:to_time]).iso8601()
    rescue Exception => e
      errors << _("to_time must be a valid datetime")
    end

    unless errors.empty?
      render json: { error: errors.to_sentence }
      return
    end

    Rails.logger.debug "Generate: f=#{from_time}, t=#{to_time}"

    @hb_report = HbReport.new "hawk-#{from_time.sub(' ', '_')}-#{to_time.sub(' ', '_')}"
    @hb_report.generate(from_time, to_time)

    respond_to do |format|
      if @hb_report.running?
        format.json do
          render json: {success: true, message: _("Please wait while report is generated...")}
        end
      else
        format.json do
          render json: { error: _("Failed to generate") }
        end
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: { error: e.message }
      end
    end
  end

  def upload
    @report = Report::Upload.new params[:report]

    respond_to do |format|
      if @report.save
        format.json do
          render json: {success: true, message: _("Upload completed.")}
        end
      else
        format.json do
          render json: { error: @report.errors.to_sentence }
        end
      end
    end
  rescue => e
    respond_to do |format|
      format.json do
        render json: { error: e.message }
      end
    end
  end

  def download
    if @report
      send_file @report.archive.realdirpath, type: @report.mimetype, filename: @report.archive.basename, x_sendfile: true
    else
      raise ActionController::RoutingError, 'Not Found'
    end
  end

  def running
    @hb_report = HbReport.new
    running = @hb_report.running?
    t = running ? @hb_report.lasttime : ["", ""]
    respond_to do |format|
      format.json do
        render json: { running: running, time: t }
      end
    end
  end

  def show

    respond_to do |format|
      format.html
      format.json do
        render json: @transitions
      end
    end
  end

  def detail
    @transition[:info] = @report.info(@hb_report, @transition[:path])
    @transition[:tags] = @report.tags(@hb_report, @transition[:path])
    respond_to do |format|
      format.html do
        render layout: false
      end
      format.json do
        render json: @transition
      end
    end
  end

  def graph
    respond_to do |format|
      format.html do
        render layout: false
      end
      format.svg do
        ok, data = @report.graph(@hb_report, @transition[:path], :svg)
        send_data data, :type => "image/svg+xml", :disposition => "inline" if ok
        render text: { error: data }, status: 500 unless ok
      end
      format.xml do
        ok, data = @report.graph(@hb_report, @transition[:path], :xml)
        render xml: data if ok
        render text: { error: data }, status: 500 unless ok
      end
      format.json do
        ok, data = @report.graph(@hb_report, @transition[:path], :json)
        render json: data if ok
        render json: { error: data }, status: 500 unless ok
      end
    end
  end

  def logs
    @transition[:logs] = @report.logs(@hb_report, @transition[:path])
    respond_to do |format|
      format.html do
        render text: [
          "<pre>",
          @transition[:logs],
          "</pre>"
        ].join("")
      end
      format.json do
        render json: @transition
      end
    end
  end

  def diff
    tidx = @transition[:index]
    if tidx >= 0 && tidx < @transitions.length-1 && @transitions.length > 1
      l = @transitions[tidx][:path]
      r = @transitions[tidx+1][:path]
      @transition[:diff] = @report.diff(@hb_report, @transition[:path], l, r, :html)
    else
      @transition[:diff] = _("No diff: Last transition")
    end

    respond_to do |format|
      format.html do
        render text: @transition[:diff]
      end
      format.json do
        render json: @transition
      end
    end
  end

  def destroy
    @hb_report = HbReport.new @report.name

    respond_to do |format|
      begin
        @report.delete(@hb_report)
        format.html do
          flash[:success] = _("Report deleted successfully")
          redirect_to reports_url
        end
        format.json do
          render json: {
            success: true,
            message: _("Report deleted successfully")
          }
        end
      rescue Exception => e
        Rails.logger.debug "#{e.message}"
        format.html do
          flash[:alert] = _("Error deleting %s") % @report.id
          redirect_to reports_url
        end
        format.json do
          render json: { error: _("Error deleting %s") % @report.id }, status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def set_title
    @title = _("History Explorer")
  end

  def set_record
    @report = Report.find params[:id]

    unless @report
      respond_to do |format|
        format.html do
          flash[:alert] = _("The report does not exist")
          redirect_to reports_url
        end
      end
    end
  end

  def set_transitions
    session[:history_session_poke] = "poke"
    set_record
    @hb_report = HbReport.new @report.name
    @transitions = Rails.cache.fetch("#{params[:id]}/#{session.id}", expires_in: 2.hours) do
      @report.transitions(@hb_report)
    end
  end

  def set_transition
    set_transitions
    tidx = 1
    tidx = params[:transition].to_i if params.has_key? :transition
    tidx -= 1 if tidx >= 0
    tidx = -1 if tidx >= @transitions.length
    @transition = @transitions[tidx]
    @transition[:index] = tidx
  end

  def current_transition
    if params[:transition].nil?
      1
    else
      params[:transition].to_i
    end
  end

  def prev_transition
    if current_transition > first_transition
      current_transition - 1
    else
      first_transition
    end
  end

  def next_transition
    if current_transition < last_transition
      current_transition + 1
    else
      last_transition
    end
  end

  def first_transition
    1
  end

  def last_transition
    @transitions.length
  end

  def window_transition
    if last_transition > 10
      case
      when current_transition <= (first_transition + 5)
        start = first_transition
        upper = 10

        start.upto(upper).to_a + ["..."]
      when current_transition >= (last_transition - 5)
        start = last_transition - 10
        upper = last_transition

        ["..."] + start.upto(upper).to_a
      else
        start = current_transition - 5
        upper = current_transition + 5

        ["..."] + start.upto(upper).to_a + ["..."]
      end
    else
      first_transition.upto(last_transition).to_a
    end
  end
end
