ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Not using ActiveRecord (no database), hence not using fixtures here

  # Add more helper methods to be used by all tests here...
end
