class PeriodLock < ApplicationRecord
  include MonthlyPeriod

  belongs_to :user

  validates :month, uniqueness: { scope: :user_id, message: "is already locked" }
end
