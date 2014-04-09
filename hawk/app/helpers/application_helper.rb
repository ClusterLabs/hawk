module ApplicationHelper
  def inject_linebreaks(e)
    lines = e.split("\n").each{|line| h(line)}.join('<br/>')
  end
end
