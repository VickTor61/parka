class PeriodLock < ApplicationRecord
  include MonthlyPeriod

  belongs_to :user

  validates :month, uniqueness: { scope: :user_id, message: "is already locked" }

  ransacker :month_text do
    Arel.sql("to_char(period_locks.month, 'YYYY-MM')")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[ month month_text ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
