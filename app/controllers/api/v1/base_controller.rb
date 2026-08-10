class Api::V1::BaseController < ActionController::Base
  include Pagy::Backend

  skip_forgery_protection

  before_action :authenticate_api_token

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from Pagy::OverflowError, with: :page_out_of_range

  private
    def authenticate_api_token
      Current.api_token = ApiToken.authenticate(bearer_token)

      return unauthorized if Current.api_token.nil?

      Current.api_token.touch_last_used
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (.+)\z/, 1]
    end

    def current_user
      Current.user
    end

    def paginated(scope)
      return unpaginated(scope) if params[:page].blank? && params[:limit].blank?

      pagy, records = pagy(scope, limit: limit_param, page: params[:page].presence || 1)

      [ records, {
        paginated: true,
        page: pagy.page,
        limit: pagy.limit,
        count: pagy.count,
        pages: pagy.pages,
        next_page: pagy.next,
        prev_page: pagy.prev
      } ]
    end

    def unpaginated(scope)
      records = scope.to_a

      [ records, { paginated: false, count: records.size } ]
    end

    def limit_param
      (params[:limit].presence || 25).to_i.clamp(1, 100)
    end

    def filter_month(scope)
      scope = scope.where(month: MonthlyPeriod.cast(params[:month])) if params[:month].present?
      scope = scope.where(month: MonthlyPeriod.cast(params[:month_from])..) if params[:month_from].present?
      scope = scope.where(month: ..MonthlyPeriod.cast(params[:month_to])) if params[:month_to].present?
      scope
    end

    def filter_amount(scope)
      scope = scope.where(amount: params[:amount_min]..) if params[:amount_min].present?
      scope = scope.where(amount: ..params[:amount_max]) if params[:amount_max].present?
      scope
    end

    def filter_category(scope)
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
      scope = scope.joins(:category).merge(Category.name_matching(params[:category_name])) if params[:category_name].present?
      scope
    end

    def filter_text(scope, column)
      return scope if params[column].blank?

      value = ActiveRecord::Base.sanitize_sql_like(params[column].to_s.strip)
      scope.where("#{scope.klass.table_name}.#{column} ILIKE ?", "%#{value}%")
    end

    def render_collection(records, meta, blueprint, **options)
      render json: { data: blueprint.render_as_hash(records, **options), meta: meta }
    end

    def render_resource(record, blueprint, status: :ok, **options)
      render json: { data: blueprint.render_as_hash(record, **options) }, status: status
    end

    def locked_months
      @locked_months ||= Current.user.period_locks.pluck(:month).to_set
    end

    def render_errors(record, status: :unprocessable_content)
      render json: { errors: record.errors.full_messages }, status: status
    end

    def unauthorized
      render json: { errors: [ "Provide a valid API token as: Authorization: Bearer <token>" ] }, status: :unauthorized
    end

    def not_found
      render json: { errors: [ "Not found" ] }, status: :not_found
    end

    def parameter_missing(exception)
      render json: { errors: [ exception.message ] }, status: :bad_request
    end

    def page_out_of_range
      render json: { errors: [ "That page does not exist" ] }, status: :not_found
    end
end
