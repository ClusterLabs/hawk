# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.config.tap do |config|
  config.session_store(
    :cookie_store,
    key: Rails.env == "production" ? "hawk" : "hawk-development",

    # Allow session cookie to persist for a (somewhat arbitrary) ten days.
    # This means when using the dashboard you won"t be required to log in
    # to all your clusters all the time.
    expire_after: 60 * 60 * 24 * 10
  )
end
