require 'test_helper'

class MainControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  def test_index_displays_status
    get :index
    assert_response :success
    assert_template 'status'
  end
end
