class ApiToken < ApplicationRecord
  LIVE_PREFIX = "sk_live".freeze
  TEST_PREFIX = "sk_test".freeze
  PREVIEW_LENGTH = 14

  def self.prefix(env = Rails.env)
    env.production? ? LIVE_PREFIX : TEST_PREFIX
  end

  belongs_to :user

  attr_reader :token

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, length: { maximum: 60 }

  before_validation :generate_token, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(created_at: :desc) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.authenticate(token)
    return if token.blank?

    active.find_by(token_digest: digest(token))
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[ name created_at last_used_at active ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def generate_token
    plaintext = "#{self.class.prefix}_#{SecureRandom.urlsafe_base64(32)}"

    @token = plaintext
    self.token_digest = self.class.digest(plaintext)
    self.token_prefix = plaintext.first(PREVIEW_LENGTH)

    plaintext
  end

  def rotate!
    generate_token
    save!
  end

  def preview
    "#{token_prefix}#{'•' * 8}"
  end

  def used?
    last_used_at.present?
  end

  def touch_last_used
    update_column(:last_used_at, Time.current)
  end
end
