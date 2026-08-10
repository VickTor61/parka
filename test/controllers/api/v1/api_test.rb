require "test_helper"

class Api::V1::ApiTest < ActionDispatch::IntegrationTest
  setup do
    @token = users(:one).api_tokens.create!(name: "test")
    @headers = { "Authorization" => "Bearer #{@token.token}" }
  end

  def body
    JSON.parse(response.body)
  end

  test "a request without a token is rejected" do
    get api_v1_categories_path

    assert_response :unauthorized
    assert_match(/Bearer/, body["errors"].first)
  end

  test "an unknown or malformed token is rejected" do
    get api_v1_categories_path, headers: { "Authorization" => "Bearer nope" }
    assert_response :unauthorized

    get api_v1_categories_path, headers: { "Authorization" => @token.token }
    assert_response :unauthorized
  end

  test "a deactivated token is rejected" do
    @token.update!(active: false)

    get api_v1_categories_path, headers: @headers
    assert_response :unauthorized
  end

  test "a rotated token stops working" do
    stale = { "Authorization" => "Bearer #{@token.token}" }
    @token.rotate!

    get api_v1_categories_path, headers: stale
    assert_response :unauthorized
  end

  test "using a token records when it was last used" do
    assert_nil @token.last_used_at

    get api_v1_categories_path, headers: @headers

    assert_not_nil @token.reload.last_used_at
  end

  test "index returns everything with meta when pagination is not asked for" do
    get api_v1_categories_path, headers: @headers

    assert_response :success
    assert_equal false, body["meta"]["paginated"]
    assert_equal 2, body["meta"]["count"]
    assert_equal 2, body["data"].size
  end

  test "index paginates when page or limit is given" do
    get api_v1_categories_path(limit: 1), headers: @headers

    assert_equal true, body["meta"]["paginated"]
    assert_equal 1, body["data"].size
    assert_equal 2, body["meta"]["count"]
    assert_equal 2, body["meta"]["pages"]
    assert_equal 2, body["meta"]["next_page"]
    assert_nil body["meta"]["prev_page"]
  end

  test "the page limit is clamped" do
    get api_v1_categories_path(limit: 9999), headers: @headers

    assert_equal 100, body["meta"]["limit"]
  end

  test "a page past the end is a clean 404" do
    get api_v1_categories_path(page: 99), headers: @headers

    assert_response :not_found
  end

  test "category index accepts a simple name filter" do
    get api_v1_categories_path(name: "mark"), headers: @headers

    assert_equal [ "Marketing" ], body["data"].map { |category| category["name"] }
  end

  test "plan index accepts explicit filters" do
    get api_v1_plans_path(category_name: "pay", month_from: "2026-01", amount_min: 10_000), headers: @headers

    assert_equal [ "Payroll" ], body["data"].map { |plan| plan["category"]["name"] }
  end

  test "actual index accepts explicit filters" do
    get api_v1_actuals_path(category_name: "mark", month: "2026-01", amount_max: 5_000, note: "ad"), headers: @headers

    assert_equal [ "Ad spend" ], body["data"].map { |actual| actual["note"] }
  end

  test "create, update and destroy a category" do
    post api_v1_categories_path, params: { category: { name: "Tools" } }, headers: @headers
    assert_response :created
    id = body["data"]["id"]

    patch api_v1_category_path(id), params: { category: { name: "Tooling" } }, headers: @headers
    assert_response :success
    assert_equal "Tooling", body["data"]["name"]

    delete api_v1_category_path(id), headers: @headers
    assert_response :no_content
  end

  test "a validation error comes back as 422 with messages" do
    post api_v1_categories_path, params: { category: { name: "Marketing" } }, headers: @headers

    assert_response :unprocessable_content
    assert_includes body["errors"], "Name has already been taken"
  end

  test "deleting a category still referenced is a conflict" do
    delete api_v1_category_path(categories(:marketing)), headers: @headers

    assert_response :conflict
    assert_match(/Cannot delete/, body["errors"].first)
  end

  test "another user's records are invisible and unreachable" do
    get api_v1_categories_path, headers: @headers
    assert_not_includes body["data"].map { |category| category["name"] }, "Ops"

    get api_v1_category_path(categories(:ops)), headers: @headers
    assert_response :not_found
  end

  test "lock enforcement applies to the api" do
    users(:one).period_locks.create!(month: "2026-01")

    patch api_v1_plan_path(plans(:marketing_january)), params: { plan: { amount: "1" } }, headers: @headers

    assert_response :unprocessable_content
    assert_match(/2026-01 is locked/, body["errors"].first)
    assert_equal 5000, plans(:marketing_january).reload.amount
  end

  test "plans and actuals report their lock state and category" do
    users(:one).period_locks.create!(month: "2026-01")

    get api_v1_plans_path, headers: @headers
    plan = body["data"].first

    assert_equal true, plan["locked"]
    assert_equal "2026-01", plan["month"]
    assert_equal "Marketing", plan["category"]["name"]
    assert_equal %w[ id name ], plan["category"].keys.sort
    assert_equal %w[ amount category created_at id locked month updated_at ], plan.keys.sort
  end

  test "an actual carries its note and category" do
    get api_v1_actuals_path, headers: @headers
    actual = body["data"].find { |record| record["note"].present? }

    assert_equal "Ad spend", actual["note"]
    assert_equal %w[ id name ], actual["category"].keys.sort
  end

  test "locks can be created and removed" do
    post api_v1_locks_path, params: { period_lock: { month: "2026-07" } }, headers: @headers
    assert_response :created
    id = body["data"]["id"]

    delete api_v1_lock_path(id), headers: @headers
    assert_response :no_content
  end

  test "the report returns rows, totals and the range" do
    get api_v1_report_path, headers: @headers

    assert_response :success
    assert_equal "All time", body["meta"]["range"]["label"]
    assert_equal "25000.0", body["meta"]["totals"]["plan"]
    assert_equal "25300.0", body["meta"]["totals"]["actual"]

    row = body["data"].first
    assert_equal "2026-01", row["month"]
    assert_equal true, row["reported"]
  end

  test "the report paginates and accepts a fiscal year" do
    get api_v1_report_path(limit: 1), headers: @headers
    assert_equal 1, body["data"].size
    assert_equal 2, body["meta"]["count"]

    get api_v1_report_path(fiscal_year: 2026), headers: @headers
    assert_equal "FY 2026", body["meta"]["range"]["label"]
  end

  test "an unreported month comes back as nulls rather than zeros" do
    users(:one).plans.create!(category: categories(:marketing), month: "2026-05", amount: 10)

    get api_v1_report_path(from: "2026-05", to: "2026-05"), headers: @headers
    row = body["data"].first

    assert_equal false, row["reported"]
    assert_nil row["actual"]
    assert_nil row["variance"]
    assert_nil row["variance_percentage"]
  end

  test "csv import reports the number of rows it took" do
    post api_v1_actuals_import_path, params: { actuals_import: { file: fixture_file_upload("actuals.csv", "text/csv") } }, headers: @headers

    assert_response :created
    assert_equal 3, body["data"]["imported_count"]
  end

  test "csv import reports per-row errors" do
    post api_v1_actuals_import_path, params: { actuals_import: { file: fixture_file_upload("actuals_unknown_category.csv", "text/csv") } }, headers: @headers

    assert_response :unprocessable_content
    assert_match(/Row 3/, body["errors"].first)
  end

  test "a missing parameter section is a clean 400" do
    post api_v1_categories_path, params: {}, headers: @headers

    assert_response :bad_request
  end
end
