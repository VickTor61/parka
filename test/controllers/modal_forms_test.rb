require "test_helper"

class ModalFormsTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup { sign_in_as users(:one) }

  test "a validation error stays inside the modal frame" do
    post categories_path, params: { category: { name: "marketing" } }, headers: TURBO_STREAM

    assert_response :unprocessable_content
    assert_select "turbo-frame#modal form"
    assert_select "li", /has already been taken/
    assert_no_match(/turbo-stream/, response.body)
  end

  test "a lock rejection stays inside the modal frame" do
    users(:one).period_locks.create!(month: "2026-06")

    post plans_path, params: { plan: { category_id: categories(:marketing).id, month: "2026-06", amount: "10" } }, headers: TURBO_STREAM

    assert_response :unprocessable_content
    assert_select "turbo-frame#modal form"
    assert_select "li", /2026-06 is locked/
  end

  test "a successful create breaks out of the frame with a redirect stream action" do
    post categories_path, params: { category: { name: "Tools" } }, headers: TURBO_STREAM

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=redirect][target=?]", categories_path
    assert_equal "Category created.", flash[:notice]
  end

  test "a successful update breaks out of the frame" do
    patch plan_path(plans(:marketing_january)), params: { plan: { amount: "9999" } }, headers: TURBO_STREAM

    assert_select "turbo-stream[action=redirect][target=?]", plans_path
    assert_equal 9999, plans(:marketing_january).reload.amount
  end

  test "a failed CSV import stays inside the modal frame" do
    post actuals_import_path, params: { actuals_import: { file: fixture_file_upload("actuals_unknown_category.csv", "text/csv") } }, headers: TURBO_STREAM

    assert_response :unprocessable_content
    assert_select "turbo-frame#modal form"
  end

  test "a successful CSV import breaks out of the frame" do
    post actuals_import_path, params: { actuals_import: { file: fixture_file_upload("actuals.csv", "text/csv") } }, headers: TURBO_STREAM

    assert_select "turbo-stream[action=redirect][target=?]", actuals_path
  end

  test "a successful lock breaks out of the frame" do
    post locks_path, params: { period_lock: { month: "2026-04" } }, headers: TURBO_STREAM

    assert_select "turbo-stream[action=redirect][target=?]", locks_path(year: 2026)
  end

  test "plain html submissions still redirect normally" do
    post categories_path, params: { category: { name: "Plain" } }

    assert_redirected_to categories_path
    assert_equal "Category created.", flash[:notice]
  end

  test "no modal form targets _top" do
    [ new_category_path, new_plan_path, new_actual_path, new_lock_path, new_actuals_import_path ].each do |path|
      get path

      assert_response :success
      assert_select "form[data-turbo-frame='_top']", { count: 0 }, "#{path} form should stay inside the modal frame"
    end
  end
end
