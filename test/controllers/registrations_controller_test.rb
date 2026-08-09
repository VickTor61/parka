require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create signs the new user in" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: { user: { email_address: " NEW@Example.com ", password: "secret-password", password_confirmation: "secret-password" } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "new@example.com", User.order(:created_at).last.email_address
  end

  test "create with a duplicate email address" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: users(:one).email_address, password: "secret-password", password_confirmation: "secret-password" } }
    end

    assert_response :unprocessable_content
    assert_nil cookies[:session_id]
  end

  test "create with a short password" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "short@example.com", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_content
  end

  test "create with a mismatched confirmation" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "mismatch@example.com", password: "secret-password", password_confirmation: "other-password" } }
    end

    assert_response :unprocessable_content
  end
end
