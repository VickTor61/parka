require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index requires authentication" do
    sign_out

    get reports_path
    assert_redirected_to new_session_path
  end

  test "index renders the rows in the range" do
    get reports_path(from: "2026-01", to: "2026-03")

    assert_response :success
    assert_select "td", text: "Marketing"
    assert_select "td", text: "$5,000.00"
  end

  test "index shows an em dash for a month with no logged entries" do
    users(:one).plans.create!(category: categories(:marketing), month: "2026-03", amount: 5000)

    get reports_path(from: "2026-03", to: "2026-03")

    assert_response :success
    assert_select "td span", text: "—", minimum: 3
  end

  test "index marks locked months" do
    users(:one).period_locks.create!(month: "2026-01")

    get reports_path(from: "2026-01", to: "2026-01")

    assert_select "td span", text: /Locked/
  end

  test "index filters by search term" do
    get reports_path(from: "2026-01", to: "2026-03", query: "payroll")

    assert_select "td", text: "Payroll"
    assert_select "td", text: "Marketing", count: 0
  end

  test "index filters by category" do
    get reports_path(from: "2026-01", to: "2026-03", category_id: categories(:marketing).id)

    assert_select "td", text: "Marketing"
    assert_select "td", text: "Payroll", count: 0
  end

  test "an explicit range does not keep the default fiscal year" do
    get reports_path(from: "2026-01", to: "2026-03")

    assert_select "span", text: /Fiscal year:/, count: 0
    assert_select "span", text: /Range: Jan 2026 – Mar 2026/
  end

  test "index paginates" do
    30.times { |index| users(:one).plans.create!(category: users(:one).categories.create!(name: "Cat #{index}"), month: "2026-01", amount: 1) }

    get reports_path(from: "2026-01", to: "2026-01")

    assert_response :success
    assert_select "tbody tr", count: 20
    assert_select "a", text: "Next"
  end

  test "a page beyond the end redirects back rather than erroring" do
    get reports_path(from: "2026-01", to: "2026-01", page: 99)

    assert_response :redirect
    follow_redirect!
    assert_select "div", /That page does not exist/
  end

  test "another user's data never appears" do
    users(:two).plans.create!(category: categories(:ops), month: "2026-01", amount: 99_999)

    get reports_path(from: "2026-01", to: "2026-01")

    assert_select "td", text: "Ops", count: 0
  end

  test "csv export returns the report as a file" do
    get reports_path(from: "2026-01", to: "2026-03", format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "parka-report-2026-01-to-2026-03.csv", response.headers["Content-Disposition"]
    assert_match "Category,Month,Plan,Actual,Variance,Variance %", response.body
    assert_match "Marketing,2026-01,5000.0,4800.0,-200.0,-4.0", response.body
  end

  test "csv export respects the active filter" do
    get reports_path(from: "2026-01", to: "2026-03", query: "payroll", format: :csv)

    assert_match "Payroll", response.body
    assert_no_match(/Marketing/, response.body)
  end
end
