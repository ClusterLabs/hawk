# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

require 'pty'
require 'json'
require 'tempfile'

module CrmScript
  def crmsh_escape(s)
    s.to_s.gsub(/[&"'><]/) { |special| "\\#{special}" }
  end
  module_function :crmsh_escape

  def splitline(line)
    begin
      if line.start_with? "Password:"
        nil
      elsif line.start_with?("{") || line.start_with?("[")
        return JSON.parse(line), nil
      else
        return nil, line
      end
      return nil, nil
    rescue JSON::ParserError => e
      return nil, e.message
    end
  end
  module_function :splitline

  def cleanerr(err)
    # remove Password: prompt from err
    err.split("\n").map do |line|
      if line.start_with? "Password:"
        ""
      else
        line
      end
    end.join("\n").strip
  end
  module_function :cleanerr

  def run(jsondata)
    user = current_user
    cmd = crmsh_escape(JSON.dump(jsondata))
    tmpf = Tempfile.new 'crmscript'
    tmpf.write("script json \"#{cmd}\"")
    tmpf.close
    cmdline = ['crm', '-f', tmpf.path]
    old_home = Util.ensure_home_for(user)
    out, err, status = Util.capture3(*cmdline)
    tmpf.unlink
    ENV['HOME'] = old_home

    if err.nil?
      err = ""
    else
      err = cleanerr err
    end

    if !err.blank?
      yield nil, err
    elsif status.exitstatus != 0
      yield nil, "Failed to apply configuration (rc=#{status.exitstatus})"
    end

    out.split("\n").each do |line|
      a, b = CrmScript.splitline line
      yield a, b if a || b
    end
  end
  module_function :run

  def current_user
    Thread.current[:current_user].call
  end
  module_function :current_user
end
