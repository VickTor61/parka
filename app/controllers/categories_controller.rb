class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    @q = Current.user.categories.ransack(search_params)
    @q.sorts = "name asc" if @q.sorts.empty?

    @pagy, @categories = pagy(@q.result, limit: limit_param)
  end

  def new
    @category = Current.user.categories.new
  end

  def create
    @category = Current.user.categories.new(category_params)

    if @category.save
      redirect_out_of_frame categories_path, notice: "Category created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_out_of_frame categories_path, notice: "Category updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @category.destroy
      redirect_to categories_path, notice: "Category deleted."
    else
      redirect_to categories_path, alert: @category.errors.full_messages.to_sentence
    end
  end

  private
    def set_category
      @category = Current.user.categories.find(params[:id])
    end

    def category_params
      params.expect(category: [ :name ])
    end
end
