class HomeController < ApplicationController
  def index
    @summary = MonthlySummary.new(user: Current.user)
    @categories_count = Current.user.categories.count
    @locked_count = Current.user.period_locks.count
  end
end
