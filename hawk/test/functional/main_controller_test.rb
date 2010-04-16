require 'test_helper'

class MainControllerTest < ActionController::TestCase

  def test_index_requires_login
    get :index
    assert_response :forbidden
  end

end
