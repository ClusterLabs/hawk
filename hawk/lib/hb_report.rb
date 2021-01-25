# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class HbReport
  # Note: outfile, errfile are based off path passed to generate() -
  # don't use them prior to a generate run, or you'll get the wrong path.
  # Lastexit is global (this is freaky/dumb - everything should be based
  # off path, and callers need to be updated to understand this - this
  # will happen when we allow multiple hb_report runs, as
  # hb_reports_controller is what cares about lastexit)
  attr_reader :path
  attr_reader :outfile
  attr_reader :errfile
  attr_reader :lastexit

  def initialize(name = nil)
    tmpbase = Rails.root.join('tmp', 'pids')
    reports = Rails.root.join('tmp', 'reports')
    tmpbase.mkpath unless tmpbase.directory?
    reports.mkpath unless reports.directory?

    @pidfile = tmpbase.join("report.pid").to_s
    @exitfile = tmpbase.join("report.exit").to_s
    @timefile = tmpbase.join("report.time").to_s
    if name
      @path = reports.join(name).to_s
      @outfile = reports.join("#{name}.stdout").to_s
      @errfile = reports.join("#{name}.stderr").to_s
    else
      @path = nil
      @outfile = tmpbase.join("report.stdout").to_s
      @errfile = tmpbase.join("report.stderr").to_s
    end
    @lastexit = File.exists?(@exitfile) ? File.new(@exitfile).read.to_i : nil
  end

  def running?
    Util.child_active(@pidfile)
  end

  def cancel!
    pid = File.new(@pidfile).read.to_i
    return 0 if pid <= 0
    Process.detach(pid)
    Process.kill("TERM", pid)
    pid
  rescue Errno::ENOENT, Errno::ESRCH, Errno::EINVAL
    0
  end

  # Returns [from_time, to_time], as strings.  Note that to_time might be
  # an empty string, if no to_time was specified when calling generate.
  def lasttime
    File.exists?(@timefile) ? File.new(@timefile).read.split(",", -1) : nil
  end

  # contents of errfile as array
  def err_lines
    err = []
    begin
      File.new(@errfile).read.split(/\n/).each do |e|
        next if e.empty?
        err << e
      end if File.exists?(@errfile)
    rescue ArgumentError => e
      # This will catch 'invalid byte sequence in UTF-8' (bnc#854060)
      err << "ArgumentError: #{e.message}"
    end
    err
  end

  # contents of errfile as array, with "INFO" lines stripped (e.g. for
  # displaying warnings after an otherwise successful run)
  def err_filtered
    err_lines.select do |e|
      !e.match(/( INFO: |(cat|tail): write error)/) && !e.match(/^tar:.*time stamp/)
    end
  end

  # Note: This assumes pidfile doesn't exist (will always blow away what's
  # there), so there's a possibility of a race (or lost hb_report status)
  # if two clients kick off generation at almost exactly the same time.
  # from_time and to_time (if specified) are expected to be in a sensible
  # format (e.g.: iso8601)
  def generate(from_time, to_time, all_nodes = true)
    [@outfile, @errfile, @exitfile, @timefile].each do |fn|
      File.unlink(fn) if File.exists?(fn)
    end
    @lastexit = nil

    f = File.new(@timefile, "w")
    f.write("#{from_time},#{to_time}")
    f.close
    pid = fork do
      args = ["-f", from_time]
      args.push("-t", to_time) if to_time
      args.push("-Z") # Remove destination directories if they exist
      args.push("-Q") # Requires a version of crm report which supports this
      args.push("-S") unless all_nodes
      args.push(@path)

      stdout, stderr, retval = run_cmd(
        auth_user, "ls", "-l"
      )
      out, err, status = Util.capture3('crm', *cmd)
      f = File.new(@outfile, "w")
      f.write(out)
      f.close
      f = File.new(@errfile, "w")
      f.write(err)
      f.close

      # Record exit status
      f = File.new(@exitfile, "w")
      f.write(status.exitstatus)
      f.close

      # Delete pidfile
      File.unlink(@pidfile)
    end
    f = File.new(@pidfile, "w")
    f.write(pid)
    f.close
    Process.detach(pid)
  end
end
