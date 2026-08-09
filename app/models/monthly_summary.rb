class MonthlySummary
  Row = Struct.new(:month, :plan, :actual, keyword_init: true) do
    def variance
      actual - plan
    end

    def logged?
      !actual.zero?
    end
  end

  def initialize(user:, from: nil, to: nil)
    @user = user
    @given_from = from&.beginning_of_month
    @given_to = to&.beginning_of_month
  end

  # With no range given the summary covers everything the user has ever recorded.
  def from
    @from ||= @given_from || earliest || Date.current.beginning_of_month
  end

  def to
    @to ||= @given_to || latest || Date.current.beginning_of_month
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

  def variance_percentage
    return if plan_total.zero?

    (variance / plan_total) * 100
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

  def range_label
    return label(from) if from == to

    "#{label(from)} – #{label(to)}"
  end

  private
    attr_reader :user

    def earliest
      [ user.plans.minimum(:month), user.actuals.minimum(:month) ].compact.min
    end

    def latest
      [ user.plans.maximum(:month), user.actuals.maximum(:month) ].compact.max
    end

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
