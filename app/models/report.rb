require "csv"

class Report
  PER_PAGE = 25
  CSV_HEADERS = [ "Category", "Month", "Plan", "Actual", "Variance", "Variance %" ].freeze

  attr_reader :from, :to, :search_params

  def initialize(user:, from: nil, to: nil, search_params: {})
    @user = user
    @from, @to = normalize_range(from, to)
    @search_params = search_params.presence || {}
  end

  def q
    @q ||= ReportRow.where(user: user).ordered.ransack(ransack_params)
  end

  def rows
    q.result.includes(:category)
  end

  def totals
    @totals ||= begin
      scope = q.result.reorder(nil)

      {
        plan: scope.sum(:plan_amount),
        actual: scope.sum(:actual_amount),
        entries: scope.sum(:entries_count)
      }
    end
  end

  def variance
    totals[:actual] - totals[:plan]
  end

  def any_rows?
    @any_rows ||= q.result.reorder(nil).exists?
  end

  def category_totals
    @category_totals ||= q.result
      .reorder(nil)
      .group("categories.name")
      .order("categories.name")
      .pluck(Arel.sql("categories.name, COALESCE(SUM(plan_amount), 0), COALESCE(SUM(actual_amount), 0)"))
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
          row.category.name,
          row.month.strftime(MonthlyPeriod::FORMAT),
          format_decimal(row.plan),
          format_decimal(row.actual),
          format_decimal(row.variance),
          row.variance_percentage && row.variance_percentage.round(2).to_s("F")
        ]
      end
    end
  end

  def filename
    "parka-report-#{from.strftime(MonthlyPeriod::FORMAT)}-to-#{to.strftime(MonthlyPeriod::FORMAT)}.csv"
  end

  def range_label
    "#{from.strftime('%b %Y')} – #{to.strftime('%b %Y')}"
  end

  private
    attr_reader :user

    def normalize_range(from, to)
      parsed_from = MonthlyPeriod.cast(from) || Date.current.beginning_of_quarter
      parsed_to = MonthlyPeriod.cast(to) || parsed_from.end_of_quarter.beginning_of_month
      parsed_from, parsed_to = parsed_to, parsed_from if parsed_to < parsed_from

      [ parsed_from, parsed_to ]
    end

    def ransack_params
      search_params.to_h.merge("month_gteq" => from, "month_lteq" => to)
    end

    def format_decimal(value)
      value&.round(2)&.to_s("F")
    end
end
