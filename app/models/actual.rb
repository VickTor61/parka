class Actual < ApplicationRecord
  include MonthlyPeriod, LockablePeriod

  belongs_to :user
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :note, length: { maximum: 500 }

  scope :ordered, -> { joins(:category).order(month: :desc, created_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[ month amount note category_id ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[ category ]
  end
end
