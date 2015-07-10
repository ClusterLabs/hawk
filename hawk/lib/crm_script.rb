# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

require 'pty'
require 'json'

module CrmScript
  def crmsh_escape(s)
    s.to_s.gsub(/[&"'>< ]/) { |special| "\\#{special}" }
  end
  module_function :crmsh_escape

  def splitline(line)
    begin
      if line.strip.eql? '"end"'
      elsif line.start_with? "Password:"
      elsif line.start_with? "ERROR:"
        return nil, line
      else
        return JSON.parse(line), nil
      end
      return nil, nil
    rescue JSON::ParserError => e
      return nil, e.message
    end
  end
  module_function :splitline

  def run(jsondata, rootpw)
    user = rootpw ? 'root' : 'hacluster'
    cmd = crmsh_escape(JSON.dump(jsondata))
    if user.eql? 'root'
      cmdline = ['/usr/bin/su', '--login', user, '-c',"crm script json " + cmd.join(" "), :stdin_data => rootpw]
    else
      cmdline = ['/usr/sbin/hawk_invoke', user, 'crm', 'script', 'json', cmd]
    end
    old_home = Util.ensure_home_for(user)
    out, err, status = Util.capture3(*cmdline)
    ENV['HOME'] = old_home
    out.split("\n").each do |line|
      a, b = CrmScript.splitline line
      yield a, b if a || b
    end
    err.split("\n").each do |line|
      a, b = _splitline line
      yield a, b if a || b
    end
  end
  module_function :run
end
