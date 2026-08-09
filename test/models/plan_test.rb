require "test_helper"

class PlanTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "a month given as YYYY-MM is stored as the first of that month" do
    plan = @user.plans.new(category: categories(:marketing), month: "2026-04", amount: 10)

    assert plan.valid?
    assert_equal Date.new(2026, 4, 1), plan.month
  end

  test "a mid-month date is normalized to the first" do
    plan = @user.plans.create!(category: categories(:marketing), month: Date.new(2026, 4, 17), amount: 10)

    assert_equal Date.new(2026, 4, 1), plan.month
  end

  test "a zero target is allowed" do
    assert @user.plans.new(category: categories(:marketing), month: "2026-04", amount: 0).valid?
  end

  test "a negative target is rejected" do
    plan = @user.plans.new(category: categories(:marketing), month: "2026-04", amount: -1)

    assert_not plan.valid?
    assert_includes plan.errors[:amount], "must be greater than or equal to 0"
  end

  test "one target per category per month" do
    duplicate = @user.plans.new(category: categories(:marketing), month: "2026-01", amount: 1)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:category_id], "already has a target for this month"
  end

  test "a plan cannot be created in a locked month" do
    @user.period_locks.create!(month: "2026-04")
    plan = @user.plans.new(category: categories(:marketing), month: "2026-04", amount: 10)

    assert_not plan.valid?
    assert_includes plan.errors[:base], "2026-04 is locked. Unlock the period before making changes."
  end

  test "a plan cannot be destroyed in a locked month" do
    @user.period_locks.create!(month: "2026-01")

    assert_not plans(:marketing_january).destroy
    assert Plan.exists?(plans(:marketing_january).id)
  end

  test "a category from another user cannot be referenced" do
    plan = users(:two).plans.new(category: categories(:marketing), month: "2026-04", amount: 10)

    assert_raises(ActiveRecord::InvalidForeignKey) { plan.save!(validate: false) }
  end
end
