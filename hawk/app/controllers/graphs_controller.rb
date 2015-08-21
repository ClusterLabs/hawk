# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class GraphsController < ApplicationController
  before_filter :login_required

  def show
    respond_to do |format|
      format.html
      format.png do
        path = Pathname.new("#{Rails.root}/tmp").join(
          Dir::Tmpname.make_tmpname(
            ["graph", ".svg"],
            nil
          )
        )

        begin
          res = Invoker.instance.crm(
            "configure",
            "graph",
            "dot",
            path.to_s,
            "svg"
          )

          if res == true
            send_data(
              path.read,
              type: "image/svg+xml",
              disposition: "inline"
            )
          else
            Rails.logger.warn("%s, failed to generate graph" % res)

            send_data(
              Rails.root.join(
                "app",
                "assets",
                "images",
                "misc",
                "blank.png"
              ).read,
              type: "image/png",
              disposition: "inline"
            )
          end
        ensure
          File.unlink path if File.exist? path
        end
      end
    end
  end
end
