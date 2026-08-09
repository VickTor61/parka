module LockablePeriod
  extend ActiveSupport::Concern

  included do
    validate :period_must_be_unlocked
    before_destroy :guard_locked_period
  end

  def locked?
    locked_months.any?
  end

  private
    def affected_months
      months = [ month ]
      months << month_was if month_changed?
      months.compact.uniq
    end

    def locked_months
      return [] if user.nil? || affected_months.empty?

      user.period_locks.where(month: affected_months).pluck(:month)
    end

    def period_must_be_unlocked
      locked_months.each { |month| errors.add(:base, lock_message(month)) }
    end

    def guard_locked_period
      return if locked_months.empty?

      locked_months.each { |month| errors.add(:base, lock_message(month)) }
      throw :abort
    end

    def lock_message(month)
      "#{month.strftime(MonthlyPeriod::FORMAT)} is locked. Unlock the period before making changes."
    end
end
