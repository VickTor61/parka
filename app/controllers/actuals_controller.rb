class ActualsController < ApplicationController
  before_action :set_actual, only: %i[ edit update destroy ]
  before_action :set_categories, only: %i[ new create edit update ]

  def index
    @actuals = Current.user.actuals.includes(:category).ordered
    @locked_months = Current.user.period_locks.pluck(:month).to_set
  end

  def new
    @actual = Current.user.actuals.new(month: params[:month])
  end

  def create
    @actual = Current.user.actuals.new(actual_params)

    if @actual.save
      redirect_to actuals_path, notice: "Entry logged."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @actual.update(actual_params)
      redirect_to actuals_path, notice: "Entry updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @actual.destroy
      redirect_to actuals_path, notice: "Entry deleted."
    else
      redirect_to actuals_path, alert: @actual.errors.full_messages.to_sentence
    end
  end

  private
    def set_actual
      @actual = Current.user.actuals.find(params[:id])
    end

    def set_categories
      @categories = Current.user.categories.ordered
    end

    def actual_params
      params.expect(actual: [ :category_id, :month, :amount, :note ])
    end
end
