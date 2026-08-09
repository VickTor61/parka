require "test_helper"

class MonthlySummaryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @summary = MonthlySummary.new(user: @user, from: Date.new(2026, 1, 1), to: Date.new(2026, 3, 1))
  end

  test "returns a row per month in the range, including empty ones" do
    assert_equal [ Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1) ], @summary.rows.map(&:month)
  end

  test "sums plans and actuals per month" do
    january = @summary.rows.first

    assert_equal 25_000, january.plan
    assert_equal 25_300, january.actual
    assert_equal 300, january.variance
  end

  test "a month with no data reports zero rather than nil" do
    february = @summary.rows.second

    assert_equal 0, february.plan
    assert_equal 0, february.actual
    assert_equal 0, february.variance
  end

  test "several entries in one category and month are summed" do
    @user.actuals.create!(category: categories(:marketing), month: "2026-02", amount: 100)
    @user.actuals.create!(category: categories(:marketing), month: "2026-02", amount: 250)

    summary = MonthlySummary.new(user: @user, from: Date.new(2026, 2, 1), to: Date.new(2026, 2, 1))
    assert_equal 350, summary.rows.first.actual
  end

  test "another user's records are excluded" do
    users(:two).plans.create!(category: categories(:ops), month: "2026-01", amount: 99_999)

    assert_equal 25_000, @summary.rows.first.plan
  end

  test "with no range it spans everything the user has recorded" do
    @user.plans.create!(category: categories(:marketing), month: "2025-11", amount: 10)
    @user.actuals.create!(category: categories(:marketing), month: "2026-04", amount: 5)
    summary = MonthlySummary.new(user: @user)

    assert_equal Date.new(2025, 11, 1), summary.from
    assert_equal Date.new(2026, 4, 1), summary.to
    assert_equal 6, summary.rows.size
    assert_equal "Nov 2025 – Apr 2026", summary.range_label
  end

  test "a user with no data still renders without erroring" do
    empty = MonthlySummary.new(user: users(:two))

    assert_not empty.any_data?
    assert_equal 1, empty.rows.size
    assert_equal 0, empty.plan_total
    assert_nil empty.variance_percentage
  end

  test "variance percentage is computed from the totals" do
    summary = MonthlySummary.new(user: @user, from: Date.new(2026, 1, 1), to: Date.new(2026, 1, 1))

    assert_equal 300, summary.variance
    assert_in_delta 1.2, summary.variance_percentage, 0.001
  end

  test "chart data carries a plan and an actual series" do
    assert_equal [ "Plan", "Actual" ], @summary.chart_data.map { |series| series[:name] }
    assert_equal [ "Jan 2026", "Feb 2026", "Mar 2026" ], @summary.chart_data.first[:data].keys
  end
end
