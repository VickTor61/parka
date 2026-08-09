module MonthlyPeriod
  extend ActiveSupport::Concern

  FORMAT = "%Y-%m".freeze

  def self.cast(value)
    case value
    when nil, "" then nil
    when Date, Time, DateTime then value.to_date.beginning_of_month
    else
      Date.strptime(value.to_s.strip, FORMAT).beginning_of_month
    end
  rescue Date::Error
    nil
  end

  included do
    attr_reader :month_input

    validate :month_must_be_present_and_parseable

    scope :ordered, -> { order(month: :desc) }
    scope :between, ->(from, to) { where(month: from..to) }
  end

  def month=(value)
    @month_input = value
    super(MonthlyPeriod.cast(value))
  end

  def month_label
    month&.strftime(FORMAT)
  end

  private
    def month_must_be_present_and_parseable
      return if month.present?

      month_input.present? ? errors.add(:month, "must be in YYYY-MM format") : errors.add(:month, :blank)
    end
end
