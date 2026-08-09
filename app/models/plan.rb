class Plan < ApplicationRecord
  include MonthlyPeriod
  include LockablePeriod

  belongs_to :user
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category_id, uniqueness: { scope: [ :user_id, :month ], message: "already has a target for this month" }

  scope :ordered, -> { joins(:category).order(month: :desc, "categories.name": :asc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[ month amount category_id ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[ category ]
  end
end
