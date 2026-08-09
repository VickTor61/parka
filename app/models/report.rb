require "csv"

class Report
  CSV_HEADERS = [ "Category", "Month", "Plan", "Actual", "Variance", "Variance %" ].freeze

  Row = Struct.new(:category_id, :category_name, :month, :plan_amount, :actual_amount, :entries_count, keyword_init: true) do
    def plan
      plan_amount || BigDecimal(0)
    end

    def reported?
      entries_count.to_i.positive?
    end

    def actual
      actual_amount if reported?
    end

    def variance
      actual - plan if reported?
    end

    def variance_percentage
      return if !reported? || plan.zero?

      (variance / plan) * 100
    end
  end

  DEFAULT_FISCAL_START_MONTH = 1

  attr_reader :from, :to, :query, :category_id, :fiscal_year, :fiscal_start_month

  def initialize(user:, from: nil, to: nil, query: nil, category_id: nil, fiscal_year: nil, fiscal_start_month: nil)
    @user = user
    @fiscal_start_month = (fiscal_start_month.presence || DEFAULT_FISCAL_START_MONTH).to_i.clamp(1, 12)
    @fiscal_year = fiscal_year.presence&.to_i
    @from, @to = @fiscal_year ? fiscal_range : normalize_range(from, to)
    @query = query.to_s.strip.presence
    @category_id = category_id.presence
  end

  def fiscal_year?
    fiscal_year.present?
  end

  # A fiscal year starting in January is just the calendar year, which is the default.
  def calendar_fiscal_year?
    fiscal_start_month == DEFAULT_FISCAL_START_MONTH
  end

  def fiscal_year_label
    return unless fiscal_year?

    calendar_fiscal_year? ? "FY #{fiscal_year}" : "FY #{fiscal_year} (#{month_name(from)} – #{month_name(to)})"
  end

  def count
    @count ||= connection.select_value("SELECT COUNT(*) FROM (SELECT 1 FROM #{union} GROUP BY combined.category_id, combined.month) grouped").to_i
  end

  def rows(limit: nil, offset: nil)
    sql = +<<~SQL
      SELECT combined.category_id,
             categories.name AS category_name,
             combined.month,
             SUM(combined.plan_amount)   AS plan_amount,
             SUM(combined.actual_amount) AS actual_amount,
             SUM(combined.entry_count)   AS entries_count
      FROM #{union}
      INNER JOIN categories ON categories.id = combined.category_id
      GROUP BY combined.category_id, categories.name, combined.month
      ORDER BY combined.month ASC, categories.name ASC
    SQL

    sql << "LIMIT #{Integer(limit)} " if limit
    sql << "OFFSET #{Integer(offset)}" if offset

    connection.select_all(sql).map { |attributes| Row.new(**attributes.symbolize_keys) }
  end

  def totals
    @totals ||= begin
      plan, actual, entries = connection.select_rows(<<~SQL).first
        SELECT COALESCE(SUM(combined.plan_amount), 0),
               COALESCE(SUM(combined.actual_amount), 0),
               COALESCE(SUM(combined.entry_count), 0)
        FROM #{union}
      SQL

      { plan: plan, actual: actual, entries: entries.to_i }
    end
  end

  def variance
    totals[:actual] - totals[:plan]
  end

  def variance_percentage
    return if totals[:plan].zero?

    (variance / totals[:plan]) * 100
  end

  def any_rows?
    count.positive?
  end

  def category_totals
    @category_totals ||= connection.select_rows(<<~SQL)
      SELECT categories.name,
             COALESCE(SUM(combined.plan_amount), 0),
             COALESCE(SUM(combined.actual_amount), 0)
      FROM #{union}
      INNER JOIN categories ON categories.id = combined.category_id
      GROUP BY categories.name
      ORDER BY categories.name ASC
    SQL
  end

  def chart_data
    [
      { name: "Plan", data: category_totals.to_h { |name, plan, _actual| [ name, plan ] }, library: { backgroundColor: "#d6d3d1", borderColor: "#d6d3d1" } },
      { name: "Actual", data: category_totals.to_h { |name, _plan, actual| [ name, actual ] }, library: { backgroundColor: "#0c0a09", borderColor: "#0c0a09" } }
    ]
  end

  def to_csv
    CSV.generate do |csv|
      csv << CSV_HEADERS

      rows.each do |row|
        csv << [
          row.category_name,
          row.month.strftime(MonthlyPeriod::FORMAT),
          decimal(row.plan),
          decimal(row.actual),
          decimal(row.variance),
          decimal(row.variance_percentage)
        ]
      end
    end
  end

  def filename
    return "parka-report-fy#{fiscal_year}.csv" if fiscal_year?
    return "parka-report-all-time.csv" if full_range?

    "parka-report-#{month_param(from) || 'start'}-to-#{month_param(to) || 'latest'}.csv"
  end

  def range_label
    return fiscal_year_label if fiscal_year?
    return "All time" if full_range?
    return "Up to #{month_name(to)}" if from.nil?
    return "From #{month_name(from)} onwards" if to.nil?

    "#{month_name(from)} – #{month_name(to)}"
  end

  def filtered?
    query.present? || category_id.present? || !full_range?
  end

  def filtered_by_range_or_category?
    category_id.present? || fiscal_year? || !full_range?
  end

  def range?(candidate_from, candidate_to)
    from == MonthlyPeriod.cast(candidate_from) && to == MonthlyPeriod.cast(candidate_to)
  end

  def full_range?
    from.nil? && to.nil?
  end

  def active_filters(categories)
    filters = []

    if fiscal_year? || !full_range?
      filters << { label: fiscal_year? ? "Fiscal year" : "Range", value: range_label, without: { query: query, category_id: category_id } }
    end

    if category_id.present?
      name = categories.find { |category| category.id.to_s == category_id.to_s }&.name

      filters << { label: "Category", value: name, without: base_params.except(:category_id) } if name
    end

    if query.present?
      filters << { label: "Search", value: query, without: base_params.except(:query) }
    end

    filters
  end

  def base_params
    {
      fiscal_year: fiscal_year,
      fiscal_start_month: (fiscal_start_month unless calendar_fiscal_year?),
      from: month_param(from),
      to: month_param(to),
      query: query,
      category_id: category_id
    }.compact
  end

  def month_param(date)
    date&.strftime(MonthlyPeriod::FORMAT)
  end

  private
    attr_reader :user

    def union
      @union ||= "(#{plans_sql} UNION ALL #{actuals_sql}) combined"
    end

    def plans_sql
      filtered(user.plans)
        .select("plans.category_id, plans.month, plans.amount AS plan_amount, NULL::numeric AS actual_amount, 0 AS entry_count")
        .to_sql
    end

    def actuals_sql
      filtered(user.actuals)
        .select("actuals.category_id, actuals.month, NULL::numeric AS plan_amount, actuals.amount AS actual_amount, 1 AS entry_count")
        .to_sql
    end

    def filtered(scope)
      scope = scope.where(month: from..) if from.present?
      scope = scope.where(month: ..to) if to.present?
      scope = scope.where(category_id: category_id) if category_id.present?
      scope = scope.joins(:category).merge(Category.name_matching(query)) if query.present?
      scope
    end

    def fiscal_range
      start = Date.new(fiscal_year, fiscal_start_month, 1)

      [ start, start.next_year.prev_month ]
    end

    # No range means the whole history — the range only narrows once it is asked for.
    def normalize_range(from, to)
      parsed_from = MonthlyPeriod.cast(from)
      parsed_to = MonthlyPeriod.cast(to)
      parsed_from, parsed_to = parsed_to, parsed_from if parsed_from && parsed_to && parsed_to < parsed_from

      [ parsed_from, parsed_to ]
    end

    def month_name(date)
      date.strftime("%b %Y")
    end

    # to_s("F") is a BigDecimal method — Integer#to_s reads its argument as a base and raises.
    def decimal(value)
      value&.to_d&.round(2)&.to_s("F")
    end

    def connection
      ApplicationRecord.connection
    end
end
