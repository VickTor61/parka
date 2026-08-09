class ReportRow < ApplicationRecord
  self.table_name = "report_rows"
  self.primary_key = nil

  belongs_to :user
  belongs_to :category

  scope :ordered, -> { joins(:category).order(:month, "categories.name") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[ month plan_amount actual_amount ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[ category ]
  end

  def readonly?
    true
  end

  def plan
    plan_amount || 0
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
