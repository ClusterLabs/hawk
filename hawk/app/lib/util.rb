# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

# Random utilities
module Util

  # From http://mentalized.net/journal/2011/04/14/ruby_how_to_check_if_a_string_is_numeric/
  def numeric?(n)
    Float(n) != nil rescue false
  end
  module_function :numeric?

  # Derived from Ruby 1.8's and 1.9's lib/open3.rb.  Returns
  # [stdin, stdout, stderr, thread].  thread.value.exitstatus
  # has the exit value of the child, but if you're calling it
  # in non-block form, you need to close stdin, out and err
  # else the process won't be complete when you try to get the
  # exit status.
  # DON'T USE THIS FUNCTION DIRECTLY - it's subject to deadlocks e.g.:
  # http://coldattic.info/shvedsky/pro/blogs/a-foo-walks-into-a-bar/posts/63
  # Rather you should prefer capture3.
  def popen3(*cmd)
    raise SecurityError, "Util::popen3 called with < 2 args" if cmd.length < 2
    pw = IO::pipe   # pipe[0] for read, pipe[1] for write
    pr = IO::pipe
    pe = IO::pipe

    pid = fork{
      # child
      pw[1].close
      STDIN.reopen(pw[0])
      pw[0].close

      pr[0].close
      STDOUT.reopen(pr[1])
      pr[1].close

      pe[0].close
      STDERR.reopen(pe[1])
      pe[1].close

      # RORSCAN_INL: cmd always has > 1 elem, so safe from shell injection
      exec(*cmd)
    }
    wait_thr = Process.detach(pid)

    pw[0].close
    pr[1].close
    pe[1].close
    pi = [pw[1], pr[0], pe[0], wait_thr]
    pw[1].sync = true
    if defined? yield
      begin
        return yield(*pi)
      ensure
        pi.each{|p| p.close if p.respond_to?(:closed) && !p.closed?}
        wait_thr.join
      end
    end
    pi
  end
  module_function :popen3

  # Derived from ruby 1.9 Open.capture3 (not just using that, as Hawk on
  # SLE 11 SP3 still has ruby 1.8).
  # Returns [stdout_str, stderr_str, status].  Pass :stdin_data => '...' if
  # you need to send something to the command on stdin.
  def capture3(*cmd)
    if Hash === cmd.last
      opts = cmd.pop.dup
    else
      opts = {}
    end
    Rails.logger.debug "Executing `#{cmd.join(' ').inspect}` through `capture3`"
    stdin_data = opts.delete(:stdin_data) || ''
    Util.popen3(*cmd) {|i, o, e, t|
      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }
      i.write stdin_data
      i.close
      [out_reader.value, err_reader.value, t.value]
    }
  end
  module_function :capture3

  def ensure_home_for(user)
    old_home = ENV['HOME']
    ENV['HOME'] = begin
      require 'etc'
      Etc.getpwnam(user)['dir']
    rescue ArgumentError
      # user doesn't exist - this can't happen[tm], but just in case
      # return an empty string so the existence test below fails
      ''
    end
    unless File.exist?(ENV['HOME'])
      # crm shell always wants to open/generate help index, so if the
      # user has no actual home directory, set it to a subdirectory
      # inside tmp/home, but make sure it's 0770, because it'll be
      # created with uid hacluster, but the user we become (in the
      # haclient group) also needs to be able to write as *that* user.
      ENV['HOME'] = File.join(Rails.root, 'tmp', 'home', user)
      unless File.exist?(ENV['HOME'])
        umask = File.umask(0002)
        Dir.mkdir(ENV['HOME'], 0770)
        File.umask(umask)
      end
    end
    old_home
  end
  module_function :ensure_home_for

  def diff(a, b)
    # call diff on a and b
    # returns [data, ok?]
    require 'tempfile.rb'
    fa = Tempfile.new 'simdiff_a'
    fb = Tempfile.new 'simdiff_b'
    begin
      fa << a
      fb << b
      fa.close
      fb.close

      out, err, status = capture3 '/usr/bin/diff', "-a", "-U", "0", "--from-file=#{fa.path}", fb.path.to_s
      if status.exitstatus == 2
        [err, false]
      else
        cleaned = [].tap do |o|
          out.lines.each do |line|
            next if line.start_with?("--- ", "+++ ", "@@ ")
            o.push line
          end
        end.join("")
        [cleaned, true]
      end
    ensure
      fa.unlink
      fb.unlink
    end
  end
  module_function :diff

  # Like %x[...], but without risk of shell injection.  Returns STDOUT
  # as a string.  STDERR is ignored. $?.exitstatus is set appropriately.
  # May block indefinitely if the command executed is expecting something
  # on STDIN (untested)
  def safe_x(*cmd)
    raise SecurityError, "Util::safe_x called with < 2 args" if cmd.length < 2
    Rails.logger.debug "Executing `#{cmd.join(' ')}` through `safe_x`"

    pr = IO::pipe   # pipe[0] for read, pipe[1] for write
    pe = IO::pipe
    pid = fork{
      # child
      fork{
        # grandchild
        pr[0].close
        STDOUT.reopen(pr[1])
        pr[1].close
        pe[0].close
        STDERR.reopen(pe[1])
        pe[1].close
        # RORSCAN_INL: cmd always has > 1 elem, so safe from shell injection
        exec(*cmd)
      }
      Process.wait
      exit!($?.exitstatus)
    }
    Process.waitpid(pid)
    pr[1].close
    pe[1].close
    out = pr[0].read()
    pr[0].close
    out
  end
  module_function :safe_x

  # Check if a child process is active by pidfile, but also cleanup stale
  # pidfile if child has gone away unexpectedly.
  def child_active(pidfile)
    active = false
    if File.exist?(pidfile)
      pid = File.new(pidfile).read.to_i
      if pid > 0
        begin
          active = Process.getpgid(pid) == Process.getpgid(0)
        rescue Errno::ESRCH
          # no such process (but nothing to do; active is already false)
        end
      end
      File.unlink(pidfile) unless active
    end
    active
  end
  module_function :child_active

  # This is intentionally pretty dumb, it's just meant to remove double
  # or single quotes around a string, for exmaple, when parsed out of the
  # booth config file.  Missing terminating quotes are ignored (i.e. the
  # whole string minus the initial quote will be returned).  Surplus data
  # (text after a closing quote) will not be returned.
  def strip_quotes(s)
    if s[0] == '"'
      s.split('"')[1]
    elsif s[0] == "'"
      s.split("'")[1]
    else
      s
    end
  end
  module_function :strip_quotes

  # Gives back a string, boolean if value is "true" or "false", or nil
  # if initial value was nil (or boolean false) and there's no default
  # TODO(should): be nice to get integers auto-converted too (could use
  # numeric? for this)
  def unstring(v, default = nil)
    v ||= default
    ['true', 'false'].include?(v.class == String ? v.downcase : v) ? v.downcase == 'true' : v
  end
  module_function :unstring

  # Does the same job bas crm_get_msec() from lib/common/utils.c
  def crm_get_msec(str)
    m = str.strip.match(/^([0-9]+)(.*)$/)
    return -1 unless m
    msec = m[1].to_i
    case m[2]
    when "ms", "msec"
      msec
    when "us", "usec"
      msec / 1000
    when "s", "sec", ""
      msec * 1000
    when "m", "min"
      msec * 60 * 1000
    when "h", "hr"
      msec * 60 * 60 * 1000
    else
      -1
    end
  end
  module_function :crm_get_msec

  # Derived from char2score() from lib/common/utils.c, minus node-score-{red,yellow,green}
  # which (unless I'm missing something) Hawk isn't paying any attention to yet.
  # TODO(should): do something sensible with node-score-{red,yellow,green} if we need it
  def char2score(score)
    case score
    when "-INFINITY"
      -1000000
    when "INFINITY"
      1000000
    when "+INFINITY"
      1000000
    when "red"
      0
    when "yellow"
      0
    when "green"
      0
    else
      s = numeric?(score) ? score.to_i : -1
      if s > 0 && s > 1000000
        1000000
      elsif s < 0 && s < -1000000
        -1000000
      else
        s
      end
    end
  end
  module_function :char2score

  # Check if some feature is supported by the installed version of pacemaker.
  # TODO(should): expand to include other checks (e.g. pcmk installed).
  def has_feature?(feature)
    case feature
    when :crm_history
      Rails.cache.fetch(:has_crm_history) {
        Util.safe_x('echo', 'quit', '|', '/usr/sbin/crm history', '2>&1')
        $?.exitstatus == 0
      }
    when :rsc_ticket
      Rails.cache.fetch(:has_rsc_ticket) {
        Util.safe_x('/usr/sbin/crm', 'configure', 'help', 'rsc_ticket', '>/dev/null', '2>&1')
        $?.exitstatus == 0
      }
    when :rsc_template
      Rails.cache.fetch(:has_rsc_template) {
        Util.safe_x('/usr/sbin/crm', 'configure', 'help', 'rsc_template', '>/dev/null', '2>&1')
        $?.exitstatus == 0
      }
    when :sim_ticket
      Rails.cache.fetch(:has_sim_ticket) {
        Util.safe_x('/usr/sbin/crm_simulate', '-h', '2>&1').include?("--ticket-grant")
      }
    when :acl_support
      Rails.cache.fetch(:has_acl_support) {
        Util.safe_x('/usr/sbin/cibadmin', '-!').split(/\s+/).include?("acls")
      }
    when :tags
      Rails.cache.fetch(:has_tags) {
        Util.safe_x('/usr/sbin/cibadmin', '-t', '5', '-Ql', '-A', '/cib/configuration/tags', '>/dev/null/', '2>&1')
        $?.exitstatus == 0
      }
    when :bundle_support
      Rails.cache.fetch(:has_bundle_support) {
        Util.safe_x('/usr/sbin/crm', 'configure', 'help', 'bundle', '>/dev/null', '2>&1')
        $?.exitstatus == 0
      }
    else
      false
    end
  end
  module_function :has_feature?

  def strip_error_message(inst)
    error_messages = []
    inst.errors.messages.each do |k, v|
      error_messages += v
    end
    error_messages.to_sentence
  end
  module_function :strip_error_message

  def acl_enabled?
    safe_x(
      '/usr/sbin/cibadmin',
      '-t', '5',
      '-Ql',
      '--xpath',
      %Q[//configuration//crm_config//nvpair[@name='enable-acl' and @value='true']] # %Q acts like a double quoted string
    ).chomp.present?
    end
  module_function :acl_enabled?

  def acl_version
    Rails.cache.fetch(:get_acl_version) do
      m = Util.safe_x('/usr/sbin/cibadmin', '-t', '5', '-Ql', '--xpath', "/cib[@validate-with").shellescape.lines.first.to_s.match(/validate-with=\"pacemaker-([0-9.]+)\"/)
      return m.captures[0].to_f if m
      2.0
    end
  end
  module_function :acl_version

  # Hash#dig from Ruby 2.3
  # https://apidock.com/ruby/Hash/dig
  def dig_hash(hash, *keys)
    res = hash
    keys.each do |key|
      res = res[key]
      return nil if res.nil?
    end
    res
  end
  module_function :dig_hash

  def get_metadata_hash(agent)
    sub_map = { 'type="string"' => 'type="text"',
                '(type="boolean".*)default="(yes|1)"' => '\1default="true"',
                '(type="boolean".*)default="(no|0)"' => '\1default="false"' }

    xml = safe_x("/usr/sbin/crm_resource", "--show-metadata", agent)
    sub_map.each { |k,v| xml.gsub!(/#{k}/i, v) }
    res = Hash.from_xml(xml)

    # For stonith agents, complete the instance attributes with the ones that
    # are built into Pacemaker and are available for all stonith-class
    # resources.
    if agent.start_with?("stonith:") && res && (res_param = dig_hash(res, "resource_agent", "parameters", "parameter"))
      # by default we assume we are using the latest stonith binary path (sles15sp1 and higher)
      # if we are using lower version, we adapt the path to other binary old accordingly
      stonith_bin = "#{Rails.configuration.x.crm_daemon_dir}/pacemaker-fenced"
      unless File.exist? "#{Rails.configuration.x.crm_daemon_dir}/pacemaker-fenced"
        stonith_bin = "/usr/lib/pacemaker/stonithd"
      end
      # execute binary and collect/append the paramters to the hash which will be visualised
      stonith_xml = safe_x(stonith_bin, "metadata")
      sub_map.each { |k,v| stonith_xml.gsub!(/#{k}/i, v) }
      stonith = Hash.from_xml(stonith_xml)

      if stonith && (stonith_param = dig_hash(stonith, "resource_agent", "parameters", "parameter"))
          res_param.concat(stonith_param)
      end
    end

    res
  end
  module_function :get_metadata_hash


  # get text child of xml element - returns empty string if elem is nil or
  # text child is empty.  trims leading and trailing whitespace
  def get_xml_text(elem)
    elem ? (elem.text.strip || '') : ''
  end
  module_function :get_xml_text

  # https://apidock.com/rails/v4.2.7/Hash/deep_symbolize_keys
  def symbolize_rescursive(hash)
    {}.tap do |h|
      hash.each { |key, value| h[key.to_sym] = map_value(value) }
    end
  end
  module_function :symbolize_rescursive

  # https://apidock.com/rails/v4.2.7/Hash/deep_symbolize_keys
  def map_value(thing)
    case thing
    when Hash
      symbolize_rescursive(thing)
    when Array
      thing.map { |v| map_value(v) }
    else
      thing
    end
  end
  module_function :map_value
end
