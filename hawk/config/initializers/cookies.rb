# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.config.tap do |config|
  config.action_dispatch.cookies_serializer = :json
end
