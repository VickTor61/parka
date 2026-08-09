require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index" do
    get plans_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { Plan.count }, 1 do
      post plans_path, params: { plan: { category_id: categories(:marketing).id, month: "2026-05", amount: "5000" } }
    end

    assert_redirected_to plans_path
    assert_equal Date.new(2026, 5, 1), Plan.order(:created_at).last.month
  end

  test "create rejects a duplicate category and month" do
    assert_no_difference -> { Plan.count } do
      post plans_path, params: { plan: { category_id: categories(:marketing).id, month: "2026-01", amount: "10" } }
    end

    assert_response :unprocessable_content
  end

  test "create is rejected in a locked month" do
    users(:one).period_locks.create!(month: "2026-06")

    assert_no_difference -> { Plan.count } do
      post plans_path, params: { plan: { category_id: categories(:marketing).id, month: "2026-06", amount: "10" } }
    end

    assert_response :unprocessable_content
    assert_select "li", /2026-06 is locked/
  end

  test "update is rejected in a locked month" do
    users(:one).period_locks.create!(month: "2026-01")
    plan = plans(:marketing_january)

    patch plan_path(plan), params: { plan: { amount: "1" } }

    assert_response :unprocessable_content
    assert_equal 5000, plan.reload.amount
  end

  test "destroy is rejected in a locked month" do
    users(:one).period_locks.create!(month: "2026-01")

    assert_no_difference -> { Plan.count } do
      delete plan_path(plans(:marketing_january))
    end

    follow_redirect!
    assert_select "div", /is locked/
  end

  test "a plan is editable again once the month is unlocked" do
    lock = users(:one).period_locks.create!(month: "2026-01")
    lock.destroy

    patch plan_path(plans(:marketing_january)), params: { plan: { amount: "7500" } }

    assert_redirected_to plans_path
    assert_equal 7500, plans(:marketing_january).reload.amount
  end
end
