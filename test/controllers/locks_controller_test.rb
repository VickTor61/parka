require "test_helper"

class LocksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index" do
    get locks_path
    assert_response :success
  end

  test "index shows the requested year" do
    get locks_path(year: 2027)

    assert_response :success
    assert_select "h2", text: "2027"
  end

  test "create locks a month" do
    assert_difference -> { PeriodLock.count }, 1 do
      post locks_path, params: { period_lock: { month: "2026-01" } }
    end

    assert_redirected_to locks_path(year: 2026)
  end

  test "create rejects a month that is already locked" do
    users(:one).period_locks.create!(month: "2026-01")

    assert_no_difference -> { PeriodLock.count } do
      post locks_path, params: { period_lock: { month: "2026-01" } }
    end

    assert_response :unprocessable_content
  end

  test "destroy unlocks a month" do
    lock = users(:one).period_locks.create!(month: "2026-01")

    assert_difference -> { PeriodLock.count }, -1 do
      delete lock_path(lock)
    end
  end

  test "another user's lock is not reachable" do
    lock = users(:two).period_locks.create!(month: "2026-01")

    assert_no_difference -> { PeriodLock.count } do
      delete lock_path(lock)
    end

    assert_redirected_to root_path
  end
end
