# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license information.

require 'pty'
require 'json'

module CrmScript
  def crmsh_escape(s)
    s.to_s.gsub(/[&"'>< ]/) { |special| "\\#{special}" }
  end
  module_function :crmsh_escape

  def run(jsondata)
    user = 'hacluster'#'root'
    old_home = ENV['HOME']
    begin
      ENV['HOME'] = begin
                      require 'etc'
                      Etc.getpwnam(user)['dir']
                    rescue ArgumentError
                      # user doesn't exist - this can't happen[tm], but just in case
                      # return an empty string so the existence test below fails
                      ''
                    end
      unless File.exists?(ENV['HOME'])
        # crm shell always wants to open/generate help index, so if the
        # user has no actual home directory, set it to a subdirectory
        # inside tmp/home, but make sure it's 0770, because it'll be
        # created with uid hacluster, but the user we become (in the
        # haclient group) also needs to be able to write as *that* user.
        ENV['HOME'] = File.join(Rails.root, 'tmp', 'home', user)
        unless File.exists?(ENV['HOME'])
          umask = File.umask(0002)
          Dir.mkdir(ENV['HOME'], 0770)
          File.umask(umask)
        end
      end

      cmd = crmsh_escape(JSON.dump(jsondata))
      PTY.spawn('/usr/sbin/hawk_invoke', user, 'crm', '-D', 'plain', 'script', 'json', cmd) do |ioout, ioin, pid|
        begin
          ioout.each do |line|
            if line.strip.eql? '"end"'
            elsif line.start_with? "ERROR:"
              yield nil, line
            else
              yield JSON.parse(line), nil
            end
          end
        rescue JSON::ParserError => e
          yield nil, e.message
        rescue Errno::EIO
        end
      end
      ENV['HOME'] = old_home
    rescue PTY::ChildExited => e
      yield nil, "The child process exited with rc=#{e.status}!"
      ENV['HOME'] = old_home
    end
  end
  module_function :run
end
