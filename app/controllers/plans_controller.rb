class PlansController < ApplicationController
  before_action :set_plan, only: %i[ edit update destroy ]
  before_action :set_categories, only: %i[ new create edit update ]

  def index
    @locked_months = Current.user.period_locks.pluck(:month).to_set
    @categories = Current.user.categories.ordered

    @q = by_status(Current.user.plans.includes(:category)).ransack(search_params)
    @q.sorts = [ "month desc", "category_name asc" ] if @q.sorts.empty?

    @pagy, @plans = pagy(@q.result, limit: limit_param)
  end

  def new
    @plan = Current.user.plans.new(month: params[:month])
  end

  def create
    @plan = Current.user.plans.new(plan_params)

    if @plan.save
      redirect_out_of_frame plans_path, notice: "Target created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @plan.update(plan_params)
      redirect_out_of_frame plans_path, notice: "Target updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @plan.destroy
      redirect_to plans_path, notice: "Target deleted."
    else
      redirect_to plans_path, alert: @plan.errors.full_messages.to_sentence
    end
  end

  private
    def by_status(scope)
      case params[:status]
      when "locked" then scope.where(month: @locked_months.to_a)
      when "open" then scope.where.not(month: @locked_months.to_a)
      else scope
      end
    end

    def set_plan
      @plan = Current.user.plans.find(params[:id])
    end

    def set_categories
      @categories = Current.user.categories.ordered
    end

    def plan_params
      params.expect(plan: [ :category_id, :month, :amount ])
    end
end
