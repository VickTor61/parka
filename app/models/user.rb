class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :actuals, dependent: :destroy
  has_many :period_locks, dependent: :destroy
  has_many :categories, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email address" }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true
end
