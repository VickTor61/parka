class Api::V1::ReportsController < Api::V1::BaseController
  def show
    report = Report.new(
      user: current_user,
      from: params[:from],
      to: params[:to],
      query: params[:query],
      category_id: params[:category_id],
      fiscal_year: params[:fiscal_year],
      fiscal_start_month: params[:fiscal_start_month]
    )

    rows, meta = report_rows(report)

    render json: {
      data: ReportRowBlueprint.render_as_hash(rows, locked_months: locked_months),
      meta: meta.merge(
        range: { from: report.month_param(report.from), to: report.month_param(report.to), label: report.range_label },
        totals: {
          plan: report.totals[:plan].to_s,
          actual: report.totals[:actual].to_s,
          variance: report.variance.to_s,
          variance_percentage: report.variance_percentage&.round(2)&.to_s,
          entries_count: report.totals[:entries]
        }
      )
    }
  end

  private
    def report_rows(report)
      return [ report.rows, { paginated: false, count: report.count } ] if params[:page].blank? && params[:limit].blank?

      pagy = Pagy.new(count: report.count, page: params[:page].presence || 1, limit: limit_param)

      [ report.rows(limit: pagy.limit, offset: pagy.offset), {
        paginated: true,
        page: pagy.page,
        limit: pagy.limit,
        count: pagy.count,
        pages: pagy.pages,
        next_page: pagy.next,
        prev_page: pagy.prev
      } ]
    end
end
