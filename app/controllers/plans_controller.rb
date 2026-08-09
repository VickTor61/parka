class PlansController < ApplicationController
  before_action :set_plan, only: %i[ edit update destroy ]
  before_action :set_categories, only: %i[ new create edit update ]

  def index
    @plans = Current.user.plans.includes(:category).ordered
    @locked_months = Current.user.period_locks.pluck(:month).to_set
  end

  def new
    @plan = Current.user.plans.new(month: params[:month])
  end

  def create
    @plan = Current.user.plans.new(plan_params)

    if @plan.save
      redirect_to plans_path, notice: "Target created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @plan.update(plan_params)
      redirect_to plans_path, notice: "Target updated."
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
