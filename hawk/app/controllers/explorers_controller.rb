# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ExplorersController < ApplicationController
  before_filter :login_required
  before_filter :god_required
  before_filter :set_title
  before_filter :set_record, only: [:show, :detail, :transition, :logs, :diff, :destroy]

  helper_method :generate_range
  helper_method :generate_start
  helper_method :generate_until
  helper_method :current_page
  helper_method :prev_page
  helper_method :next_page
  helper_method :first_page
  helper_method :last_page
  helper_method :window_page

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Report.all
      end
    end
  end

  def generate
    @report = Report::Generate.new params[:explorer]

    respond_to do |format|
      if @report.save
        format.json do
          render json: {
            success: true,
            message: _("Report successfully generated")
          }
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

  def upload
    @report = Report::Upload.new params[:explorer]

    respond_to do |format|
      if @report.save
        format.json do
          render json: {
            success: true,
            message: _("Report successfully uploaded")
          }
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

  def show
    respond_to do |format|
      format.html
    end
  end

  def detail
    # parmas[:id]
    # params[:page]

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

  def transition
    # parmas[:id]
    # params[:page]

    respond_to do |format|
      format.html do
        render text: [
          view_context.image_tag("/dummy/transition.png")
        ].join("")
      end
    end
  end

  def logs
    # parmas[:id]
    # params[:page]

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
    # parmas[:id]
    # params[:page]

    respond_to do |format|
      format.html do
        render text: Rails.root.join("public", "dummy", "diff.html").read.html_safe
      end
    end
  end

  def destroy
    respond_to do |format|
      if @report.delete
        format.html do
          flash[:success] = _("Report deleted successfully")
          redirect_to exporers_url
        end
        format.json do
          render json: {
            success: true,
            message: _("Report deleted successfully")
          }
        end
      else
        format.html do
          flash[:alert] = _("Error deleting %s") % @report.id
          redirect_to explorers_url
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
          redirect_to explorers_url
        end
      end
    end

    if current_page != 1
      if current_page > last_page || current_page < first_page
        respond_to do |format|
          format.html do
            flash[:alert] = _("The page is out of scope")
            redirect_to show_explorer_url(id: @report.id, page: 1)
          end
        end
      end
    end
  end

  def generate_range
    [
      generate_start,
      generate_until
    ].join(" - ")
  end

  def generate_start
    @generate_start ||= Time.zone
      .now
      .ago(6.days)
      .beginning_of_day
      .strftime("%b %d, %Y %H:%M")
  end

  def generate_until
    @generate_until ||= Time.zone
      .now
      .end_of_day
      .strftime("%b %d, %Y %H:%M")
  end

  def current_page
    if params[:page].nil?
      1
    else
      params[:page].to_i
    end
  end

  def prev_page
    if current_page > first_page
      current_page - 1
    else
      first_page
    end
  end

  def next_page
    if current_page < last_page
      current_page + 1
    else
      last_page
    end
  end

  def first_page
    1
  end

  def last_page
    30
  end

  def window_page
    if last_page > 10
      case
      when current_page <= (first_page + 5)
        start = first_page
        upper = 10

        start.upto(upper).to_a + ["..."]
      when current_page >= (last_page - 5)
        start = last_page - 10
        upper = last_page

        ["..."] + start.upto(upper).to_a
      else
        start = current_page - 5
        upper = current_page + 5

        ["..."] + start.upto(upper).to_a + ["..."]
      end
    else
      first_page.upto(last_page).to_a
    end
  end



  def current_report
    @current_report ||= Report.new report_path
  end

  # before_filter :init_params

  # def index
  #   @errors = []
  #   @cache = []

  #   ts_re = "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}"
  #   explorer_path.entries.sort.reverse.each do |f|
  #     m = f.basename.to_s.match(/^hb_report-hawk-(#{ts_re})-(#{ts_re}).tar.bz2$/)
  #     next unless m
  #     @cache << {
  #       :from_time => m[1].sub("_", " "),
  #       :to_time =>   m[2].sub("_", " "),
  #     }
  #   end

  #   if params[:delete]
  #     require "fileutils"
  #     # TODO(must): won't work with uploads
  #     FileUtils.remove_entry_secure(@report_path) if File.exists?(@report_path)
  #     FileUtils.remove_entry_secure(current_report.path) if File.exists?(current_report.path)
  #     FileUtils.remove_entry_secure(current_report.outfile) if File.exists?(current_report.outfile)
  #     FileUtils.remove_entry_secure(current_report.errfile) if File.exists?(current_report.errfile)
  #     redirect_to :action => "index"
  #     return
  #   end

  #   if params[:display] && !current_report.running?
  #     # Now we either generate if a report for that time doesn't exist, or display if one does.
  #     # TODO(must): this doesn't handle the case where a generate run fails utterly; it'll
  #     # probably just keep trying to generate the hb_report indefinitely.
  #     pcmk_version = nil
  #     m = %x[cibadmin -!].match(/^Pacemaker ([^ ]+) \(Build: ([^)]+)\)/)
  #     pcmk_version = "#{m[1]}-#{m[2]}" if m
  #     if File.exists?(@report_path)
  #       # Have to blow this away if it exists (i.e. is a cached report), else
  #       # prior cibadmin calls on individual PE inputs will have wrecked their mtimes.
  #       FileUtils.remove_entry_secure(current_report.path) if File.exists?(current_report.path)
  #       @peinputs = []
  #       peinputs_raw, err, status = Util.capture3("crm", "history", :stdin_data => "source #{@report_path}\npeinputs\n")
  #       if status.exitstatus == 0
  #         peinputs_raw.split(/\n/).each do |path|
  #           next unless File.exists?(path)
  #           @peinputs << {
  #             :timestamp => File.mtime(path).strftime("%Y-%m-%d %H:%M:%S"),
  #             :basename  => File.basename(path, ".bz2"),
  #             :filename  => File.basename(path),
  #             :path      => path.sub("#{explorer_path.to_s}/", ''),  # only use relative portion
  #             :node      => path.split(File::SEPARATOR)[-3]
  #           }
  #           v = peinput_version(path)
  #           @peinputs[-1][:info] = v == pcmk_version ? nil : (v ?
  #             _("PE Input created by different Pacemaker version (%{version})" % { :version => v }) :
  #             _("Pacemaker version not present in PE Input"))
  #         end
  #         # sort is going to be off for identical mtimes (stripped back to the second),
  #         # so need secondary sort by filename
  #       end
  #       # exitstatus will be 1 if (somehow) there's no peinputs, but this shouldn't
  #       # be reported as an error.
  #       @errors += current_report.err_filtered
  #       err.split(/\n/).each do |e|
  #         @errors << e
  #       end
  #     elsif params[:refresh]
  #       # This is a "refresh" request, thus we're trying to get updated status
  #       # from an existing run, except hb_report is not running and there's no
  #       # report file, thus something died horribly.
  #       # TODO(should): This whole sequence might still be a little fragile: re-evaluate.
  #       @peinputs = []   # neccessary for correct display to trigger
  #       @errors += current_report.err_filtered
  #     else
  #       current_report.generate(@from_time, true, @to_time)
  #     end
  #   end
  # end

  # # Remarkably similar to MainController::sim_get (kinda)
  # # Note reliance on hb_report directory strucutre - if that ever changes, code
  # # here will need to change too.
  # def get
  #   unless params[:basename] && params[:node]
  #     render :status => 400, :content_type => "text/plain",
  #       :inline => _('Required parameters "basename" and "node" not specified')
  #     return
  #   end
  #   # next two are a bit rough
  #   params[:basename].gsub!(/[^\w-]/, "")
  #   params[:node].gsub!(/[^\w_-]/, "")
  #   tname = "#{params[:node]}/pengine/#{params[:basename]}.bz2"
  #   params[:path].gsub!("..", "") # tear out possible relative junk
  #   tpath = explorer_path.join(params[:path]).to_s
  #   case params[:file]
  #   when "pe-input"
  #     send_file tpath, :type => "application/x-bzip"
  #   when "info"
  #     cmd = "transition #{tname} nograph"
  #     cmd = "transition log #{tname}" if params[:log]
  #     out, err, status = Util.run_as("root", "crm", "history", :stdin_data => "source #{@report_path}\n#{cmd}\n")
  #     info = out + err

  #     info.strip!
  #     # TODO(should): option to increase verbosity level
  #     info = _("No details available") if info.empty?

  #     info.insert(0, _("Error:") + "\n") unless status.exitstatus == 0

  #     send_data info, :type => "text/plain", :disposition => "inline"
  #   when "graph"
  #     # Apparently we can't rely on the dot file existing in the hb_report, so we
  #     # just use ptest to generate it.  Note that this will fail if hacluster doesn't
  #     # have read access to the pengine files (although, this should be OK, because
  #     # they're created by hacluster by default).
  #     require "tempfile"
  #     tmpfile = Tempfile.new("hawk_dot")
  #     tmpfile.close
  #     Util.safe_x("/usr/sbin/crm_simulate", "-x", tpath,
  #       params[:format] == "xml" ? "-G" : "-D", tmpfile.path)
  #     # TODO(must): handle failure of above

  #     if params[:format] == "xml"
  #       # Can't use send_file here, server whines about file not existing(?!?)
  #       send_data File.new(tmpfile.path).read, :type => (params[:munge] == "txt" ? "text/plain" : "text/xml"), :disposition => "inline"
  #     else
  #       png, err, status = Util.capture3("/usr/bin/dot", "-Tpng", tmpfile.path)
  #       if status.exitstatus == 0
  #         send_data png, :type => "image/png", :disposition => "inline"
  #       else
  #         render :status => 500, :content_type => "text/plain", :inline => _("Error:") + "\n#{err}"
  #       end
  #     end

  #     tmpfile.unlink
  #   else
  #     head :not_found
  #   end
  # end

  # def diff
  #   unless params[:left] && params[:right]
  #     render :status => 400, :content_type => "text/plain",
  #       :inline => _('Required parameters "left" and "right" not specified')
  #     return
  #   end

  #   # l and r are filenames
  #   l = params[:left]
  #   r = params[:right]

  #   # Allows html inline into dialog or plain text if link opened in new window
  #   format = params[:format] == "html" ? "html" : ""

  #   if (l && r)
  #     out, err, status = Util.run_as("root", "crm", "history", :stdin_data => "source #{@report_path}\ndiff #{l} #{r} status #{format}\ndiff #{l} #{r} #{format}\n")
  #     info = out + err

  #     info.strip!
  #     # TODO(should): option to increase verbosity level
  #     info = _("No details available") if info.empty?

  #     if status.exitstatus == 0
  #       if format == "html"
  #         info += <<-eos
  #           <table>
  #             <tr>
  #               <th>#{_('Legend')}:</th>
  #               <td class="diff_add">#{_('Added')}</th>
  #               <td class="diff_chg">#{_('Changed')}</th>
  #               <td class="diff_sub">#{_('Deleted')}</th>
  #             </tr>
  #           </table>
  #           <script type="text/javascript">
  #             /* Get rid of line numbers (bnc#807503) */
  #             $("th.diff_header").each(function() { this.colSpan = 1; });
  #             $("td.diff_header").hide();
  #           </script>
  #         eos
  #       end
  #     else
  #       info.insert(0, _("Error:") + "\n")
  #     end

  #     send_data info, :type => (format == "html" ? "text/html" : "text/plain"), :disposition => "inline"
  #   else
  #     head :not_found
  #   end
  # end

  # # This handles the case where some crazy thing has been entered by the user
  # # (e.g.: 2014-00-00) which would ordinarily throw an exception resulting in
  # # a 500 error
  # def time_param(val, default)
  #   begin
  #     Time.parse(val)
  #   rescue
  #     default
  #   end
  # end

  # def init_params
  #   lasttime = current_report.lasttime
  #   if current_report.running? && lasttime
  #     # If we're already running, use the last run time & date
  #     @from_time, @to_time = lasttime
  #   else
  #     # Start 24 hours ago by default
  #     @from_time = time_param(params[:from_time], Time.now - 86400)
  #     @to_time = time_param(params[:to_time], Time.now)

  #     # Ensure from_time is earlier than to_time.  Should probably make sure they're
  #     # not idendical (kind of pointless doing a zero minute hb_report...)
  #     @from_time, @to_time = @to_time, @from_time if @from_time > @to_time

  #     # ...and now back to a string
  #     @from_time = @from_time.strftime("%Y-%m-%d %H:%M")
  #     @to_time = @to_time.strftime("%Y-%m-%d %H:%M")
  #   end

  #   if params[:uploaded_report]
  #     # TODO(must): handle overwriting existing files
  #     #             (note that hb_reports from hawk seem to all extract to hb_report-hawk, not their filename?)
  #     #             e.g.:bug-781207_hb_report-hawk.tar.bz2)
  #     # TODO(must): verify original_filename doesn't contain evil
  #     uploaded_io = params[:uploaded_report]
  #     @upload_name = uploaded_io.original_filename
  #     @report_path = Rails.root.join('tmp', 'explorer', 'uploads', @upload_name)
  #     File.open(@report_path, 'wb') do |file|
  #       file.write(uploaded_io.read)
  #     end
  #     # @report_name actually not really used when uploading (*ugh*)
  #     @report_name = "uploads/#{File.basename(@report_path, '.tar.bz2')}"
  #   elsif params[:upload_name]
  #     # TODO(must): dupe of above, kinda, fix.  Also unsafe.
  #     @upload_name = params[:upload_name]
  #     @report_path = Rails.root.join('tmp', 'explorer', 'uploads', @upload_name)
  #     @report_name = "uploads/#{File.basename(@report_path, '.tar.bz2')}"
  #   else
  #     @report_name = "hb_report-hawk-#{@from_time.sub(' ','_')}-#{@to_time.sub(' ','_')}"
  #     @report_path = explorer_path.join("#{@report_name}.tar.bz2").to_s
  #   end

  #   current_report.path = explorer_path.join(@report_name).to_s
  # end

  # def peinput_version(path)
  #   nvpair = %x[CIB_file=#{path} cibadmin -Q --xpath "/cib/configuration//crm_config//nvpair[@name='dc-version']" 2>/dev/null]
  #   m = nvpair.match(/value="([^"]+)"/)
  #   return nil unless m
  #   m[1]
  # end

end
