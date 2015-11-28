# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class GraphsController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def show
    respond_to do |format|
      format.html
      format.svg do
        path = Pathname.new("#{Rails.root}/tmp").join(Dir::Tmpname.make_tmpname(["graph", ".svg"], nil))
        begin
          _out, err, rc = Invoker.instance.no_log do |invoker|
            invoker.crm("configure", "graph", "dot", path.to_s, "svg")
          end
          if rc == 0
            send_data path.read, type: "image/svg+xml", disposition: "inline"
          else
            l = err.lines
            h = 16 * (l.length + 1)
            errmsg = <<END
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="640" height="#{h}">
END
            y = 16
            errmsg += l.map do |line|
              ret = <<END
<text style="font-family:arial,sans;font-size:12px;fill:#ed1c24;text-anchor:left;" x="10" y="#{y}">
END
              ret += line
              ret += '</text>'
              y += 16
              ret
            end.join("\n")
            errmsg += '</svg>'
            send_data errmsg, type: "image/svg+xml", disposition: "inline"
          end
        ensure
          File.unlink path if File.exist? path
        end
      end
    end
  end

  protected

  def set_title
    @title = _("Cluster Graph")
  end

  def set_cib
    @cib = current_cib
  end
end
