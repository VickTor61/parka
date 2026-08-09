require "test_helper"

class ReportTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  def report(**options)
    Report.new(user: @user, **{ from: "2026-01", to: "2026-03" }.merge(options))
  end

  test "reproduces the assignment's sample table" do
    @user.plans.create!(category: categories(:marketing), month: "2026-02", amount: 5000)
    @user.plans.create!(category: categories(:payroll), month: "2026-02", amount: 20000)
    @user.actuals.create!(category: categories(:payroll), month: "2026-02", amount: 19800)

    rows = report.rows.map { |row| [ row.month.strftime("%Y-%m"), row.category_name, row.plan, row.actual, row.variance, row.variance_percentage&.round(2) ] }

    assert_equal [ "2026-01", "Marketing", 5000, 4800, -200, -4.00 ], rows[0]
    assert_equal [ "2026-01", "Payroll", 20000, 20500, 500, 2.50 ], rows[1]
    assert_equal [ "2026-02", "Marketing", 5000, nil, nil, nil ], rows[2]
    assert_equal [ "2026-02", "Payroll", 20000, 19800, -200, -1.00 ], rows[3]
  end

  test "a month with no logged entries reports nil rather than zero" do
    @user.plans.create!(category: categories(:marketing), month: "2026-03", amount: 5000)
    row = report.rows.last

    assert_not row.reported?
    assert_nil row.actual
    assert_nil row.variance
    assert_nil row.variance_percentage
  end

  test "an entry of zero is reported, and is distinct from a missing actual" do
    @user.plans.create!(category: categories(:marketing), month: "2026-03", amount: 100)
    @user.actuals.create!(category: categories(:marketing), month: "2026-03", amount: 0)
    row = report.rows.last

    assert row.reported?
    assert_equal 0, row.actual
    assert_equal(-100, row.variance)
    assert_equal(-100, row.variance_percentage)
  end

  test "a plan of zero yields no variance percentage rather than a crash or NaN" do
    @user.plans.create!(category: categories(:marketing), month: "2026-03", amount: 0)
    @user.actuals.create!(category: categories(:marketing), month: "2026-03", amount: 300)
    row = report.rows.last

    assert_equal 0, row.plan
    assert_equal 300, row.variance
    assert_nil row.variance_percentage
  end

  test "spend in a category with no target is included with a plan of zero" do
    @user.actuals.create!(category: categories(:payroll), month: "2026-03", amount: 750)
    row = report.rows.last

    assert_equal "Payroll", row.category_name
    assert_equal 0, row.plan
    assert_equal 750, row.actual
    assert_nil row.variance_percentage
  end

  test "several entries in one category and month are summed into a single row" do
    @user.actuals.create!(category: categories(:marketing), month: "2026-01", amount: 200)

    row = report.rows.first
    assert_equal 5000, row.plan
    assert_equal 5000, row.actual
    assert_equal 2, row.entries_count
  end

  test "rows fall outside the range are excluded" do
    @user.plans.create!(category: categories(:marketing), month: "2026-09", amount: 1)

    assert_equal 2, report.count
    assert_equal 3, report(to: "2026-09").count
  end

  test "the range is inclusive of both endpoints" do
    assert_equal 2, report(from: "2026-01", to: "2026-01").count
  end

  test "a reversed range is swapped rather than returning nothing" do
    reversed = report(from: "2026-03", to: "2026-01")

    assert_equal Date.new(2026, 1, 1), reversed.from
    assert_equal Date.new(2026, 3, 1), reversed.to
    assert_equal 2, reversed.count
  end

  test "no range means the whole history" do
    all_time = Report.new(user: @user)

    assert_nil all_time.from
    assert_nil all_time.to
    assert all_time.full_range?
    assert_equal "All time", all_time.range_label
    assert_equal 2, all_time.count
  end

  test "an unparseable range is treated as no range rather than raising" do
    fallback = Report.new(user: @user, from: "not a month", to: nil)

    assert_nil fallback.from
    assert_nil fallback.to
    assert fallback.full_range?
  end

  test "an open-ended range narrows from one side only" do
    @user.plans.create!(category: categories(:marketing), month: "2026-09", amount: 1)

    assert_equal 1, Report.new(user: @user, from: "2026-03").count
    assert_equal "From Mar 2026 onwards", Report.new(user: @user, from: "2026-03").range_label
    assert_equal 2, Report.new(user: @user, to: "2026-02").count
    assert_equal "Up to Feb 2026", Report.new(user: @user, to: "2026-02").range_label
  end

  test "a fiscal year defaults to the calendar year" do
    fy = Report.new(user: @user, fiscal_year: "2026")

    assert_equal Date.new(2026, 1, 1), fy.from
    assert_equal Date.new(2026, 12, 1), fy.to
    assert fy.calendar_fiscal_year?
    assert_equal "FY 2026", fy.range_label
  end

  test "a fiscal year can start in any month and spans twelve of them" do
    fy = Report.new(user: @user, fiscal_year: "2026", fiscal_start_month: "4")

    assert_equal Date.new(2026, 4, 1), fy.from
    assert_equal Date.new(2027, 3, 1), fy.to
    assert_not fy.calendar_fiscal_year?
    assert_equal "FY 2026 (Apr 2026 – Mar 2027)", fy.range_label
  end

  test "a fiscal year narrows the rows it returns" do
    @user.plans.create!(category: categories(:marketing), month: "2027-06", amount: 1)

    assert_equal 2, Report.new(user: @user, fiscal_year: "2026").count
    assert_equal 1, Report.new(user: @user, fiscal_year: "2027").count
  end

  test "an april fiscal year reaches into the next calendar year and drops the previous january" do
    @user.plans.create!(category: categories(:marketing), month: "2027-01", amount: 1)
    fy = Report.new(user: @user, fiscal_year: "2026", fiscal_start_month: "4")

    assert_equal [ Date.new(2027, 1, 1) ], fy.rows.map(&:month)
    assert_equal 1, fy.count
  end

  test "a fiscal year overrides any explicit range" do
    fy = Report.new(user: @user, fiscal_year: "2026", from: "2020-01", to: "2020-02")

    assert_equal Date.new(2026, 1, 1), fy.from
    assert_equal Date.new(2026, 12, 1), fy.to
  end

  test "an out of range fiscal start month is clamped" do
    assert_equal 12, Report.new(user: @user, fiscal_year: "2026", fiscal_start_month: "99").fiscal_start_month
    assert_equal 1, Report.new(user: @user, fiscal_year: "2026", fiscal_start_month: "0").fiscal_start_month
  end

  test "a fiscal year appears as a filter chip and names the csv" do
    fy = Report.new(user: @user, fiscal_year: "2026")

    assert_equal [ "Fiscal year" ], fy.active_filters(@user.categories).map { |filter| filter[:label] }
    assert_equal "parka-report-fy2026.csv", fy.filename
  end

  test "search matches a category name case insensitively" do
    assert_equal [ "Marketing" ], report(query: "mark").rows.map(&:category_name)
  end

  test "search treats wildcards as literal characters" do
    assert_empty report(query: "%").rows
  end

  test "filtering by category limits the rows" do
    assert_equal [ "Payroll" ], report(category_id: categories(:payroll).id).rows.map(&:category_name)
  end

  test "totals and variance are computed over the whole range, not one page" do
    totals = report.totals

    assert_equal 25_000, totals[:plan]
    assert_equal 25_300, totals[:actual]
    assert_equal 2, totals[:entries]
    assert_equal 300, report.variance
  end

  test "variance percentage is computed over the whole range" do
    assert_equal 300, report.variance
    assert_in_delta 1.2, report.variance_percentage, 0.001
  end

  test "variance percentage is nil when nothing is planned" do
    @user.plans.destroy_all

    assert_nil report.variance_percentage
    assert_equal 25_300, report.variance
  end

  test "totals respect the active filter" do
    assert_equal 5_000, report(category_id: categories(:marketing).id).totals[:plan]
  end

  test "limit and offset page through the rows" do
    assert_equal [ "Marketing" ], report.rows(limit: 1, offset: 0).map(&:category_name)
    assert_equal [ "Payroll" ], report.rows(limit: 1, offset: 1).map(&:category_name)
  end

  test "another user's records never appear" do
    users(:two).plans.create!(category: categories(:ops), month: "2026-01", amount: 99_999)

    assert_equal 2, report.count
    assert_equal 25_000, report.totals[:plan]
  end

  test "chart data carries a plan and an actual series per category" do
    assert_equal [ "Plan", "Actual" ], report.chart_data.map { |series| series[:name] }
    assert_equal({ "Marketing" => 5000, "Payroll" => 20000 }, report.chart_data.first[:data])
  end

  test "active filters describe a non-default range, category and search" do
    filters = report(category_id: categories(:marketing).id, query: "mark").active_filters(@user.categories)

    assert_equal [ "Range", "Category", "Search" ], filters.map { |filter| filter[:label] }
    assert_equal [ "Jan 2026 – Mar 2026", "Marketing", "mark" ], filters.map { |filter| filter[:value] }
  end

  test "the default quarter is not reported as an active filter" do
    assert_empty Report.new(user: @user).active_filters(@user.categories)
    assert_not Report.new(user: @user).filtered_by_range_or_category?
  end

  test "removing one filter keeps the others" do
    filters = report(category_id: categories(:marketing).id, query: "mark").active_filters(@user.categories)
    search_removal = filters.find { |filter| filter[:label] == "Search" }[:without]

    assert_nil search_removal[:query]
    assert_equal categories(:marketing).id.to_s, search_removal[:category_id].to_s
    assert_equal "2026-01", search_removal[:from]
    assert_equal "2026-03", search_removal[:to]
  end

  test "a category filter for an unknown id produces no chip" do
    assert_empty report(category_id: "999999").active_filters(@user.categories).select { |filter| filter[:label] == "Category" }
  end

  test "csv export contains a header and every row in the range" do
    rows = CSV.parse(report.to_csv)

    assert_equal Report::CSV_HEADERS, rows.first
    assert_equal 3, rows.size
    assert_equal [ "Marketing", "2026-01", "5000.0", "4800.0", "-200.0", "-4.0" ], rows[1]
  end

  test "csv exports a row that has spend but no plan" do
    @user.actuals.create!(category: categories(:marketing), month: "2026-03", amount: 25)

    assert_equal [ "Marketing", "2026-03", "0.0", "25.0", "25.0", nil ], CSV.parse(report.to_csv).last
  end

  test "a row with no plan still reports money, not an integer" do
    @user.actuals.create!(category: categories(:marketing), month: "2026-03", amount: 25)
    row = report.rows.last

    assert_kind_of BigDecimal, row.plan
    assert_kind_of BigDecimal, row.variance
  end

  test "csv leaves actual, variance and variance %% blank for an unreported month" do
    @user.plans.create!(category: categories(:marketing), month: "2026-03", amount: 5000)

    assert_equal [ "Marketing", "2026-03", "5000.0", nil, nil, nil ], CSV.parse(report.to_csv).last
  end

  test "csv is not paginated" do
    12.times { |index| @user.plans.create!(category: @user.categories.create!(name: "Extra #{index}"), month: "2026-03", amount: 1) }

    assert_equal 15, CSV.parse(report.to_csv).size
  end
end
