# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ReportsController < ApplicationController
  before_filter :login_required
  before_filter :god_required
  before_filter :set_title
  before_filter :set_record, only: [:show, :detail, :graph, :logs, :diff, :destroy, :download]

  helper_method :current_transition
  helper_method :prev_transition
  helper_method :next_transition
  helper_method :first_transition
  helper_method :last_transition
  helper_method :window_transition
  helper_method :report_details

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
    @report = Report::Generate.new params[:report]
    unless @report.valid?
      render json: { error: @report.errors.to_sentence }
      return
    end

    @hb_report = HbReport.new @report.name
    @hb_report.generate(@report.from_time, true, @report.to_time)

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

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: report_details
      end
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

  def detail
    # params[:id]
    # params[:event]

    respond_to do |format|
      format.html do
        render text: [
          "<pre>",
          Rails.root.join("public", "dummy", "details.txt").read.html_safe,
          "</pre>"
        ].join("")
      end
    end
  end

  def graph
    # params[:id]
    # params[:event]

    respond_to do |format|
      format.html do
        render text: [
          view_context.image_tag("/dummy/transition.png")
        ].join("")
      end
    end
  end

  def logs
    # params[:id]
    # params[:event]

    respond_to do |format|
      format.html do
        render text: [
          "<pre>",
          Rails.root.join("public", "dummy", "logs.txt").read.html_safe,
          "</pre>"
        ].join("")
      end
    end
  end

  def diff
    # params[:id]
    # params[:event]

    respond_to do |format|
      format.html do
        render text: Rails.root.join("public", "dummy", "diff.html").read.html_safe
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

  def report_details
    {}
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
    30
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
