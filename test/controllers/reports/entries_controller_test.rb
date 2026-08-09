require "test_helper"

class Reports::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index lists the entries behind a report cell" do
    get reports_entries_path(category_id: categories(:marketing).id, month: "2026-01")

    assert_response :success
    assert_select "span", text: "$4,800.00"
    assert_select "span", text: "Ad spend"
  end

  test "each entry links through to the actuals table filtered to that cell" do
    get reports_entries_path(category_id: categories(:marketing).id, month: "2026-01")

    expected = actuals_path(q: { category_id_eq: categories(:marketing).id, month_eq: Date.new(2026, 1, 1) })

    assert_select "a[href=?]", expected
    assert_select "a", text: "Open in Actuals"
  end

  test "the drill-down no longer offers an inline edit" do
    get reports_entries_path(category_id: categories(:marketing).id, month: "2026-01")

    assert_select "a[href=?]", edit_actual_path(actuals(:marketing_january)), count: 0
  end

  test "the linked actuals table shows only that category and month" do
    users(:one).actuals.create!(category: categories(:payroll), month: "2026-02", amount: 5)

    get actuals_path(q: { category_id_eq: categories(:marketing).id, month_eq: Date.new(2026, 1, 1) })

    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: "Marketing"
  end

  test "index reports an empty month without erroring" do
    get reports_entries_path(category_id: categories(:marketing).id, month: "2026-09")

    assert_response :success
    assert_select "p", text: /No entries logged/
  end

  test "an unparseable month is rejected" do
    get reports_entries_path(category_id: categories(:marketing).id, month: "not-a-month")

    assert_redirected_to root_path
  end

  test "another user's category is not reachable" do
    get reports_entries_path(category_id: categories(:ops).id, month: "2026-01")

    assert_redirected_to root_path
  end
end
