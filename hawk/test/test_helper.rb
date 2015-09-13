# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"

class ActiveSupport::TestCase
end
