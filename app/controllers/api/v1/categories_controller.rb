class Api::V1::CategoriesController < Api::V1::BaseController
  before_action :set_category, only: %i[ show update destroy ]

  def index
    scope = filter_text(current_user.categories, :name).ordered
    records, meta = paginated(scope)

    render_collection records, meta, CategoryBlueprint
  end

  def show
    render_resource @category, CategoryBlueprint
  end

  def create
    category = current_user.categories.new(category_params)

    if category.save
      render_resource category, CategoryBlueprint, status: :created
    else
      render_errors category
    end
  end

  def update
    if @category.update(category_params)
      render_resource @category, CategoryBlueprint
    else
      render_errors @category
    end
  end

  def destroy
    if @category.destroy
      head :no_content
    else
      render_errors @category, status: :conflict
    end
  end

  private
    def set_category
      @category = current_user.categories.find(params[:id])
    end

    def category_params
      params.expect(category: [ :name ])
    end
end
