class Actual < ApplicationRecord
  include MonthlyPeriod
  include LockablePeriod

  belongs_to :user
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :note, length: { maximum: 500 }

  scope :ordered, -> { joins(:category).order(month: :desc, created_at: :desc) }
end
