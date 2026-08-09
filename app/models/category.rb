class Category < ApplicationRecord
  belongs_to :user
  has_many :plans, dependent: :restrict_with_error
  has_many :actuals, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :user_id, case_sensitive: false }

  scope :ordered, -> { order(:name) }
  scope :name_matching, ->(query) { where("categories.name ILIKE ?", "%#{sanitize_sql_like(query.to_s.strip)}%") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[ name created_at ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
