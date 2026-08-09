class Reports::EntriesController < ApplicationController
  def index
    @category = Current.user.categories.find(params[:category_id])
    @month = MonthlyPeriod.cast(params[:month])

    raise ActiveRecord::RecordNotFound if @month.nil?

    @entries = Current.user.actuals.where(category: @category, month: @month).order(created_at: :desc)
    @locked = Current.user.period_locks.exists?(month: @month)
  end
end
