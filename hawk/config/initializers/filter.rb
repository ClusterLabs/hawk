# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

Rails.application.config.tap do |config|
  config.filter_parameters += [
    :password,
    :rootpw
  ]
end
