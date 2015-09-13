# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

module ExplorerHelper
  def in_progress_msg
    _("Data collection in progress (%{from_time} to %{to_time})...") % { from_time: @from_time, to_time: @to_time }
  end

  def report_path
      Rails.root.join("tmp", "pids", "report")
  end

  def explorer_path
    path = Rails.root.join("tmp", "explorer")
    path.mkpath unless path.directory?
    path
  end
end
