require "test_helper"

class ActualTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "a zero amount is allowed" do
    assert @user.actuals.new(category: categories(:marketing), month: "2026-04", amount: 0).valid?
  end

  test "a negative amount is rejected" do
    actual = @user.actuals.new(category: categories(:marketing), month: "2026-04", amount: -1)

    assert_not actual.valid?
    assert_includes actual.errors[:amount], "must be greater than or equal to 0"
  end

  test "the database rejects a negative amount even without validations" do
    actual = @user.actuals.new(category: categories(:marketing), month: "2026-04", amount: -1)

    assert_raises(ActiveRecord::StatementInvalid) { actual.save!(validate: false) }
  end

  test "several entries can share a category and month" do
    @user.actuals.create!(category: categories(:marketing), month: "2026-01", amount: 10)

    assert @user.actuals.new(category: categories(:marketing), month: "2026-01", amount: 20).valid?
  end

  test "a note is optional" do
    assert @user.actuals.new(category: categories(:marketing), month: "2026-04", amount: 10).valid?
  end
end
