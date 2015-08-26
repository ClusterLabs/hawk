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

  def run(jsondata, rootpw)
    user = rootpw.nil? ? 'hacluster' : 'root'
    cmd = crmsh_escape(JSON.dump(jsondata))

    tmpf = Tempfile.new 'crmscript'
    tmpf.write("script json \"#{cmd}\"")
    tmpf.close
    File.chmod(0666, tmpf.path)

    if user.eql? 'root'
      cmdline = ['/usr/bin/su', '--login', user, '-c',"crm -f #{tmpf.path}", :stdin_data => rootpw.lines.first]
    else
      cmdline = ['/usr/sbin/hawk_invoke', user, 'crm', '-f', tmpf.path]
    end
    old_home = Util.ensure_home_for(user)
    out, err, status = Util.capture3(*cmdline)
    tmpf.unlink
    ENV['HOME'] = old_home

    if status.exitstatus != 0
      yield nil, "Error (rc=#{status.exitstatus}): #{err}"
    elsif !err.blank?
      yield nil, "Error: #{err}"
    end

    out.split("\n").each do |line|
      a, b = CrmScript.splitline line
      yield a, b if a || b
    end
  end
  module_function :run
end
