class ReportsController < ApplicationController
  def index
    @report = Report.new(
      user: Current.user,
      from: params[:from],
      to: params[:to],
      query: params[:query],
      category_id: params[:category_id],
      fiscal_year: params[:fiscal_year],
      fiscal_start_month: params[:fiscal_start_month]
    )
    @categories = Current.user.categories.ordered
    @locked_months = Current.user.period_locks.pluck(:month).to_set

    respond_to do |format|
      format.html do
        @pagy = Pagy.new(count: @report.count, page: params[:page] || 1, limit: limit_param)
        @rows = @report.rows(limit: @pagy.limit, offset: @pagy.offset)
      end

      format.csv { send_data @report.to_csv, filename: @report.filename, type: "text/csv" }
    end
  end
end
