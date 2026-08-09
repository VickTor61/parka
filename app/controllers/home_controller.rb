class HomeController < ApplicationController
  MONTHS_SHOWN = 6

  def index
    to = Date.current.beginning_of_month
    from = to - (MONTHS_SHOWN - 1).months

    @summary = MonthlySummary.new(user: Current.user, from: from, to: to)
    @categories_count = Current.user.categories.count
    @locked_count = Current.user.period_locks.count
  end
end
