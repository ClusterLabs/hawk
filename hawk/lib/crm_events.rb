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
    begin
      File.open(path, 'a') do |f|
        f.flock(File::LOCK_EX)
        f.truncate(0) if f.mtime < 1.day.ago
        f << cmd
        f << "@@COMMAND-END@@\n"
      end
      Rails.logger.debug "CrmEvents.instance.push #{cmd}"
    rescue Exception => e
      Rails.logger.debug "CrmEvents: #{e.message}"
    end
  end

  def cmds
    begin
      File.open(path, "r") do |f|
        f.flock(File::LOCK_SH)
        f.read.split("@@COMMAND-END@@\n").map do |cmd|
          cmd.strip
        end
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
