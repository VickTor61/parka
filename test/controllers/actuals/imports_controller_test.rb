require "test_helper"

class Actuals::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "new" do
    get new_actuals_import_path
    assert_response :success
  end

  test "a valid CSV imports every row" do
    assert_difference -> { Actual.count }, 3 do
      post actuals_import_path, params: { actuals_import: { file: csv("actuals.csv") } }
    end

    assert_redirected_to actuals_path
  end

  test "an unknown category rejects the whole file" do
    assert_no_difference -> { Actual.count } do
      post actuals_import_path, params: { actuals_import: { file: csv("actuals_unknown_category.csv") } }
    end

    assert_response :unprocessable_content
    assert_select "li", /Row 3: category "Nonexistent" does not exist/
  end

  test "a bad month reports the offending row" do
    assert_no_difference -> { Actual.count } do
      post actuals_import_path, params: { actuals_import: { file: csv("actuals_bad_month.csv") } }
    end

    assert_response :unprocessable_content
    assert_select "li", /Row 2: Month must be in YYYY-MM format/
  end

  test "a locked month rejects the whole file" do
    users(:one).period_locks.create!(month: "2026-03")

    assert_no_difference -> { Actual.count } do
      post actuals_import_path, params: { actuals_import: { file: csv("actuals.csv") } }
    end

    assert_response :unprocessable_content
    assert_select "li", /is locked/
  end

  test "a missing file is reported" do
    post actuals_import_path, params: { actuals_import: {} }

    assert_response :unprocessable_content
    assert_select "li", /File is required/
  end

  test "the template downloads as a csv" do
    get actuals_import_template_path(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "parka-actuals-template.csv", response.headers["Content-Disposition"]
    assert_match "month,category,amount,note", response.body
  end

  test "the template requires authentication" do
    sign_out

    get actuals_import_template_path(format: :csv)
    assert_redirected_to new_session_path
  end

  private
    def csv(name)
      fixture_file_upload(name, "text/csv")
    end
end
