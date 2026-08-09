require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a well formed email address" do
    user = User.new(email_address: "not-an-email", password: "secret-password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is not a valid email address"
  end

  test "requires a unique email address" do
    user = User.new(email_address: users(:one).email_address, password: "secret-password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "requires a password of at least 8 characters" do
    user = User.new(email_address: "shorty@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end
end
