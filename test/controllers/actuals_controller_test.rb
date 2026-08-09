require "test_helper"

class ActualsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index" do
    get actuals_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { Actual.count }, 1 do
      post actuals_path, params: { actual: { category_id: categories(:marketing).id, month: "2026-02", amount: "1200.50", note: "Conference" } }
    end

    assert_redirected_to actuals_path
  end

  test "several entries can share a category and month" do
    assert_difference -> { Actual.count }, 1 do
      post actuals_path, params: { actual: { category_id: categories(:marketing).id, month: "2026-01", amount: "50" } }
    end
  end

  test "a negative amount is rejected" do
    assert_no_difference -> { Actual.count } do
      post actuals_path, params: { actual: { category_id: categories(:marketing).id, month: "2026-02", amount: "-5" } }
    end

    assert_response :unprocessable_content
    assert_select "li", /Amount must be greater than or equal to 0/
  end

  test "create is rejected in a locked month" do
    users(:one).period_locks.create!(month: "2026-02")

    assert_no_difference -> { Actual.count } do
      post actuals_path, params: { actual: { category_id: categories(:marketing).id, month: "2026-02", amount: "10" } }
    end

    assert_response :unprocessable_content
    assert_select "li", /2026-02 is locked/
  end

  test "an entry cannot be moved into a locked month" do
    users(:one).period_locks.create!(month: "2026-09")
    actual = actuals(:marketing_january)

    patch actual_path(actual), params: { actual: { month: "2026-09" } }

    assert_response :unprocessable_content
    assert_equal Date.new(2026, 1, 1), actual.reload.month
  end

  test "an entry cannot be moved out of a locked month" do
    users(:one).period_locks.create!(month: "2026-01")
    actual = actuals(:marketing_january)

    patch actual_path(actual), params: { actual: { month: "2026-09" } }

    assert_response :unprocessable_content
    assert_equal Date.new(2026, 1, 1), actual.reload.month
  end

  test "destroy is rejected in a locked month" do
    users(:one).period_locks.create!(month: "2026-01")

    assert_no_difference -> { Actual.count } do
      delete actual_path(actuals(:marketing_january))
    end
  end

  test "a month in YYYY-MM format is stored as the first of the month" do
    post actuals_path, params: { actual: { category_id: categories(:marketing).id, month: "2026-07", amount: "10" } }

    assert_equal Date.new(2026, 7, 1), Actual.order(:created_at).last.month
  end

  test "an unparseable month is rejected with a clear message" do
    post actuals_path, params: { actual: { category_id: categories(:marketing).id, month: "July 2026", amount: "10" } }

    assert_response :unprocessable_content
    assert_select "li", /Month must be in YYYY-MM format/
  end
end
