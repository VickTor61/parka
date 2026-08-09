class Api::V1::PlansController < Api::V1::BaseController
  before_action :set_plan, only: %i[ show update destroy ]

  def index
    scope = current_user.plans.includes(:category).ransack(search_params).result.ordered
    records, meta = paginated(scope)

    render_collection records, meta, PlanBlueprint, locked_months: locked_months
  end

  def show
    render_resource @plan, PlanBlueprint, locked_months: locked_months
  end

  def create
    plan = current_user.plans.new(plan_params)

    if plan.save
      render_resource plan, PlanBlueprint, status: :created, locked_months: locked_months
    else
      render_errors plan
    end
  end

  def update
    if @plan.update(plan_params)
      render_resource @plan, PlanBlueprint, locked_months: locked_months
    else
      render_errors @plan
    end
  end

  def destroy
    if @plan.destroy
      head :no_content
    else
      render_errors @plan, status: :conflict
    end
  end

  private
    def set_plan
      @plan = current_user.plans.find(params[:id])
    end

    def plan_params
      params.expect(plan: [ :category_id, :month, :amount ])
    end
end
