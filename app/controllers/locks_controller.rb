class LocksController < ApplicationController
  def index
    @year = (params[:year].presence || Date.current.year).to_i
    @period_locks = Current.user.period_locks.ordered
    @locks_by_month = Current.user.period_locks.index_by(&:month)
  end

  def new
    @period_lock = Current.user.period_locks.new(month: params[:month])
  end

  def create
    @period_lock = Current.user.period_locks.new(period_lock_params)

    if @period_lock.save
      redirect_to locks_path(year: @period_lock.month.year), notice: "#{@period_lock.month_label} is now locked."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    period_lock = Current.user.period_locks.find(params[:id])
    period_lock.destroy

    redirect_to locks_path(year: period_lock.month.year), notice: "#{period_lock.month_label} is now open."
  end

  private
    def period_lock_params
      params.expect(period_lock: [ :month ])
    end
end
