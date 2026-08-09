require "test_helper"

class TableSearchTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "categories search by name" do
    get categories_path(q: { name_cont: "mark" })

    assert_select "td", text: "Marketing"
    assert_select "td", text: "Payroll", count: 0
  end

  test "plans search by category name" do
    get plans_path(q: { category_name_cont: "payroll" })

    assert_select "td", text: "Payroll"
    assert_select "td", text: "Marketing", count: 0
  end

  test "plans filter by amount range" do
    get plans_path(q: { amount_gteq: "10000" })

    assert_select "td", text: "Payroll"
    assert_select "td", text: "Marketing", count: 0
  end

  test "plans filter by category" do
    get plans_path(q: { category_id_eq: categories(:marketing).id })

    assert_select "td", text: "Marketing"
    assert_select "td", text: "Payroll", count: 0
  end

  test "plans filter by locked status separates locked from open months" do
    users(:one).plans.create!(category: categories(:marketing), month: "2026-05", amount: 1)
    users(:one).period_locks.create!(month: "2026-01")

    get plans_path(status: "locked")
    assert_select "tbody tr", count: 2
    assert_select "td", text: "May 2026", count: 0

    get plans_path(status: "open")
    assert_select "tbody tr", count: 1
    assert_select "td", text: "May 2026"
  end

  test "changing rows per page keeps the active filter" do
    users(:one).period_locks.create!(month: "2026-01")

    get plans_path(status: "locked", limit: 10)

    assert_select "input[name=status][value=locked]"
    assert_select "select[name=limit] option[selected][value=10]"
  end

  test "a crafted sort vector on a non-sortable column is ignored" do
    get categories_path(q: { s: "user_id desc" })

    assert_response :success
    assert_select "td", text: "Marketing"
  end

  test "actuals search matches a note" do
    get actuals_path(q: { category_name_or_note_cont: "Ad spend" })

    assert_select "td", text: "Ad spend"
    assert_select "tbody tr", count: 1
  end

  test "actuals search matches a category name" do
    get actuals_path(q: { category_name_or_note_cont: "payroll" })

    assert_select "td", text: "Payroll"
    assert_select "tbody tr", count: 1
  end

  test "actuals filter by status" do
    users(:one).period_locks.create!(month: "2026-01")

    get actuals_path(status: "open")
    assert_select "tbody tr", count: 0
  end

  test "locks search by month text" do
    users(:one).period_locks.create!(month: "2026-01")
    users(:one).period_locks.create!(month: "2027-05")

    get locks_path(q: { month_text_cont: "2027" })

    assert_select "tbody tr", count: 1
    assert_select "td", text: "Jan 2026", count: 0
  end

  test "a search matching nothing renders the empty state" do
    get categories_path(q: { name_cont: "nothing-matches-this" })

    assert_response :success
    assert_select "h2", text: "No matching categories"
  end

  test "search only ever sees the current user's rows" do
    get categories_path(q: { name_cont: "ops" })

    assert_select "td", text: "Ops", count: 0
    assert_select "h2", text: "No matching categories"
  end

  test "rows per page is honoured and clamped" do
    30.times { |index| users(:one).categories.create!(name: "Cat #{index}") }

    get categories_path(limit: 10)
    assert_select "tbody tr", count: 10

    get categories_path(limit: 9999)
    assert_select "tbody tr", count: 32
  end

  test "an unpermitted ransack attribute is ignored rather than raising" do
    get categories_path(q: { user_id_eq: users(:two).id })

    assert_response :success
    assert_select "td", text: "Marketing"
  end
end
