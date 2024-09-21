# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ReportsController < ApplicationController
  before_action :login_required
  before_action :set_title
  before_action :set_record, only: [:show, :destroy, :download, :cache]
  before_action :set_transition, only: [:display, :detail, :graph, :logs, :diff, :pefile, :status, :cib]

  helper_method :current_transition
  helper_method :prev_transition
  helper_method :next_transition
  helper_method :first_transition
  helper_method :last_transition
  helper_method :window_transition
  helper_method :next_transitions
  helper_method :prev_transitions
  helper_method :format_date
  helper_method :transition_tooltip
  helper_method :history_text_markup
  helper_method :history_log_markup

  def index
    if params[:from_time].present? && params[:to_time].present?
      from_time = params[:from_time]
      to_time = params[:to_time]
      @hb_report = HbReport.new make_report_name(from_time, to_time)
      @hb_report.generate(from_time, to_time)
      redirect_to reports_url
      return
    end

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
    params[:report].permit!
    from_time = parse_time params[:report][:from_time], errors
    to_time = parse_time params[:report][:to_time], errors

    unless errors.empty?
      render json: { error: errors.full_messages.to_sentence }
      return
    end

    @hb_report = HbReport.new make_report_name(from_time, to_time)
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
    @report = Report::Upload.new params[:report].permit!

    respond_to do |format|
      if @report.save
        format.json do
          render json: {success: true, message: _("Upload completed.")}
        end
      else
        format.json do
          render json: { error: @report.errors.full_messages.to_sentence }
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
      send_file @report.archive.realdirpath, type: @report.mimetype, filename: @report.archive.basename.to_s.gsub(/[ +-]/, '_'), x_sendfile: true
    else
      raise ActionController::RoutingError, 'Not Found'
    end
  end

  def running
    respond_to do |format|
      format.json do
        @hb_report = HbReport.new
        running = @hb_report.running?
        t = running ? @hb_report.lasttime : nil
        rc = @hb_report.report_generated?
        render json: { running: running, time: (t || ["", ""]), report_generated: rc[:code], msg: rc[:msg] }
      end
    end
  end

  def cancel
    respond_to do |format|
      format.json do
        @hb_report = HbReport.new
        pid = @hb_report.cancel!
        if pid > 0
          render json: { cancelled: pid }
        else
          render json: { error: _("Could not cancel report collection"), status: :unprocessable_entity }
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def display
    if @transition.nil?
      hbr = HbReport.new @report.name
      @node_events = @report.node_events hbr
      @resource_events = @report.resource_events hbr
    end
    respond_to do |format|
      format.html
      format.json do
        render json: @transitions
      end
    end
  end

  def pefile
    fn = Pathname.new(@hb_report.path).join(@transition[:path])
    send_file fn.to_s, type: "application/x-bzip", filename: @transition[:filename], x_sendfile: true
  end

  def detail
    info, err = @report.info(@hb_report, @transition[:path])
    @transition[:info] = info
    @transition[:info_err] = err
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

  def cib
    cib = @report.cib(@hb_report, @transition[:path])
    respond_to do |format|
      format.html do
        render html: ['<pre><code class="hljs crmsh">', cib, '</code></pre>'].join("").html_safe
      end
      format.json do
        render json: {cib: cib}
      end
    end
  end

  def logs
    logs, logs_err = @report.logs(@hb_report, @transition[:path])
    respond_to do |format|
      format.html do
        txt = ['<pre>', history_log_markup(logs), '</pre>']
        unless logs_err.empty?
          txt.concat(['<pre>', history_text_markup(logs_err), '</pre>'])
        end
        render html: txt.join("").html_safe
      end
      format.json do
        @transition[:logs] = logs
        @transition[:logs_err] = logs_err
        render json: @transition
      end
    end
  end

  def diff
    tidx = @transition[:index]
    if tidx > 0 && tidx < @transitions.length
      l = @transitions[tidx-1][:path]
      r = @transitions[tidx][:path]
      @transition[:diff] = @report.diff(@hb_report, @transition[:path], l, r, :html)
    else
      @transition[:diff] = _("Cannot display diff for initial transition.")
    end

    respond_to do |format|
      format.html do
        render html: @transition[:diff].html_safe
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

    fail Cib::RecordNotFound.new(_("The report does not exist"), redirect_to: reports_path) if @report.nil?
  end

  def set_transitions
    session[:history_session_poke] = "poke"
    set_record
    @hb_report = HbReport.new @report.name
    @transitions = Rails.cache.fetch("#{params[:id]}/#{session.id}", expires_in: 2.hours) do
      @report.transitions(@hb_report).select do |t|
        # TODO(must): handle this better
        !t.key?(:error)
      end
    end
  end

  def set_transition
    set_transitions
    if params.has_key? :transition
      tidx = params[:transition].to_i
      tidx -= 1 if tidx > 0
      tidx = -1 if tidx >= @transitions.length
      curr_transition = @transitions[tidx]
      if curr_transition.nil?
        @transition = {}
      else
        @transition = @transitions[tidx]
        @transition[:index] = tidx
      end
    else
      @transition = nil
    end
  end

  def current_transition
    if params[:transition].nil?
      0
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

        start.upto(upper).to_a + ["end"]
      when current_transition >= (last_transition - 5)
        start = last_transition - 10
        upper = last_transition

        ["begin"] + start.upto(upper).to_a
      else
        start = current_transition - 5
        upper = current_transition + 5

        ["begin"] + start.upto(upper).to_a + ["end"]
      end
    else
      first_transition.upto(last_transition).to_a
    end
  end

  def prev_transitions
    (window_transition[1] - 1).downto(first_transition).to_a[0..20]
  end

  def next_transitions
    (window_transition[-2] + 1).upto(last_transition).to_a[0..20]
  end


  def format_date(t)
    t = DateTime.parse(t) if t.is_a? String
    t = t.to_time if t.is_a? DateTime
    if t.nil?
      ''
    else
      t.utc.strftime('%F %T %Z')
    end
  end

  def parse_time(t, errors)
    begin
      DateTime.parse(t).utc.iso8601
    rescue Exception => e
      errors << _("must be a valid datetime")
      nil
    end
  end

  def make_report_name(f, t)
    "hawk-#{f.sub(' ', '_')}-#{t.sub(' ', '_')}"
  end

  def transition_tooltip(transition)
    tr = @transitions[transition.to_i-1]
    format_date(tr[:timestamp])
  end

  def history_line_markup(line)
    line.gsub!(/\b(offline|error|unclean|stopped)/i, '<span class="text-danger"><strong>\\1</strong></span>')
    line.gsub!(/\b(warning)/i, '<span class="text-warning"><strong>\\1</strong></span>')
    line.gsub!(/\b(info|notice)/i, '<span class="text-info"><strong>\\1</strong></span>')
    line.gsub!(/\b(online|started)/i, '<span class="text-success"><strong>\\1</strong></span>')
    line
  end

  def history_text_markup(text)
    text.lines.map do |line|
      history_line_markup line
    end.join("").html_safe
  end

  def history_log_markup(text)
    history_text_markup text
  end
end
