require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when signed out" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "renders when signed in" do
    sign_in_as users(:one)

    get root_path
    assert_response :success
  end
end
