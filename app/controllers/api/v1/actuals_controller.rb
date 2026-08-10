class Api::V1::ActualsController < Api::V1::BaseController
  before_action :set_actual, only: %i[ show update destroy ]

  def index
    scope = current_user.actuals.includes(:category)
    scope = filter_month(scope)
    scope = filter_amount(scope)
    scope = filter_category(scope)
    scope = filter_text(scope, :note)
    scope = scope.ordered
    records, meta = paginated(scope)

    render_collection records, meta, ActualBlueprint, locked_months: locked_months
  end

  def show
    render_resource @actual, ActualBlueprint, locked_months: locked_months
  end

  def create
    actual = current_user.actuals.new(actual_params)

    if actual.save
      render_resource actual, ActualBlueprint, status: :created, locked_months: locked_months
    else
      render_errors actual
    end
  end

  def update
    if @actual.update(actual_params)
      render_resource @actual, ActualBlueprint, locked_months: locked_months
    else
      render_errors @actual
    end
  end

  def destroy
    if @actual.destroy
      head :no_content
    else
      render_errors @actual, status: :conflict
    end
  end

  private
    def set_actual
      @actual = current_user.actuals.find(params[:id])
    end

    def actual_params
      params.expect(actual: [ :category_id, :month, :amount, :note ])
    end
end
