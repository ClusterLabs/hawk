module ExplorerHelper
  def in_progress_msg 
    _("Data collection in progress (%{from_time} to %{to_time})...") % { :from_time => @from_time, :to_time => @to_time }
  end
end
