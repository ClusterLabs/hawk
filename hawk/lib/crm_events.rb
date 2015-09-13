# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

# CrmEvents:
# Stores a log of crm commands executed by hawk.
# This log can then be retrieved and displayed in the UI.

require 'singleton'

class CrmEvents
  include Singleton

  def push(cmd)
    cmd = cmd.join(" ") if cmd.is_a? Array
    Rails.logger.debug "CrmEvents.instance.push #{cmd}"
    begin
      File.delete(path) if File.mtime(path) < Time.now.ago(1.day)
    rescue
    end
    begin
      open(path, 'a') do |f|
        f << cmd
        f << "@@COMMAND-END@@\n"
      end
    rescue Exception => e
      Rails.logger.debug "CrmEvents: #{e.message}"
    end
  end

  def cmds
    begin
      File.read(path).split("@@COMMAND-END@@\n").map do |cmd|
        cmd.strip
      end
    rescue
      []
    end
  end

  private

  def path
    Rails.root.join("tmp", "commands.log")
  end
end
