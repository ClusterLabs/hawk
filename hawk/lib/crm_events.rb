# Copyright (c) 2015 Kristoffer Gronlund <kgronlund@suse.com>
# See COPYING for license.

# CrmEvents:
# Stores a log of crm commands executed by hawk.
# This log can then be retrieved and displayed in the UI.

class CrmEvents
  attr_accessor :cmds
  attr_accessor :limit

  def initialize
    Rails.logger.debug "CrmEvents.initialize"
    @cmds = []
    @limit = 100
  end

  def push(cmd)
    Rails.logger.debug "CrmEvents.instance.push #{cmd} (#{@cmds.length})"
    cmd = cmd.join(" ") if cmd.is_a? Array
    @cmds << cmd
    len = @cmds.length
    @cmds = @cmds.drop(len - @limit) if len > @limit
  end

  def cmds
    @cmds
  end

  def self.instance
    @@instance ||= new
  end

  private_class_method :new
end
