class ReportsController < ApplicationController
  def index
    @report = Report.new(user: Current.user, from: params[:from], to: params[:to], search_params: search_params)
    @locked_months = Current.user.period_locks.pluck(:month).to_set

    respond_to do |format|
      format.html { @pagy, @rows = pagy(@report.rows, limit: Report::PER_PAGE) }
      format.csv { send_data @report.to_csv, filename: @report.filename, type: "text/csv" }
    end
  end

  private
    def search_params
      params[:q]&.permit(:category_name_cont)&.to_h || {}
    end
end
