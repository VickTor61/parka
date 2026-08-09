class MonthlySummary
  Row = Struct.new(:month, :plan, :actual, keyword_init: true) do
    def variance
      actual - plan
    end

    def logged?
      actual.positive? || actual.negative?
    end
  end

  attr_reader :from, :to

  def initialize(user:, from:, to:)
    @user = user
    @from = from.beginning_of_month
    @to = to.beginning_of_month
  end

  def rows
    @rows ||= months.map do |month|
      Row.new(month: month, plan: plan_totals.fetch(month, 0), actual: actual_totals.fetch(month, 0))
    end
  end

  def plan_total
    rows.sum(&:plan)
  end

  def actual_total
    rows.sum(&:actual)
  end

  def variance
    actual_total - plan_total
  end

  def chart_data
    [
      { name: "Plan", data: rows.to_h { |row| [ label(row.month), row.plan ] }, library: { backgroundColor: "#d6d3d1", borderColor: "#d6d3d1" } },
      { name: "Actual", data: rows.to_h { |row| [ label(row.month), row.actual ] }, library: { backgroundColor: "#0c0a09", borderColor: "#0c0a09" } }
    ]
  end

  def any_data?
    rows.any? { |row| row.plan.positive? || row.logged? }
  end

  private
    attr_reader :user

    def months
      current = from
      [].tap do |list|
        while current <= to
          list << current
          current = current.next_month
        end
      end
    end

    def plan_totals
      @plan_totals ||= user.plans.between(from, to).group(:month).sum(:amount)
    end

    def actual_totals
      @actual_totals ||= user.actuals.between(from, to).group(:month).sum(:amount)
    end

    def label(month)
      month.strftime("%b %Y")
    end
end
