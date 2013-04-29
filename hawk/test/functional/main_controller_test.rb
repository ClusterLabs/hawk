require 'test_helper'

class MainControllerTest < ActionController::TestCase

  def test_index_requires_login
    get :index
    assert_redirected_to new_session_path
  end

end
