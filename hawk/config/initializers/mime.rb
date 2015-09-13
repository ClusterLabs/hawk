# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Mime::Type.tap do |config|
  config.register "image/svg+xml", :svg
end
