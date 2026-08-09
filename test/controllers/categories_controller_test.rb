require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index requires authentication" do
    sign_out

    get categories_path
    assert_redirected_to new_session_path
  end

  test "index lists only the current user's categories" do
    get categories_path

    assert_response :success
    assert_select "td", text: "Marketing"
    assert_select "td", text: "Ops", count: 0
  end

  test "create" do
    assert_difference -> { users(:one).categories.count }, 1 do
      post categories_path, params: { category: { name: "Tools" } }
    end

    assert_redirected_to categories_path
  end

  test "create with a duplicate name" do
    assert_no_difference -> { Category.count } do
      post categories_path, params: { category: { name: "marketing" } }
    end

    assert_response :unprocessable_content
  end

  test "destroy is blocked while plans or actuals reference the category" do
    assert_no_difference -> { Category.count } do
      delete category_path(categories(:marketing))
    end

    follow_redirect!
    assert_select "div", /Cannot delete record/
  end

  test "destroy succeeds once nothing references the category" do
    category = users(:one).categories.create!(name: "Temporary")

    assert_difference -> { Category.count }, -1 do
      delete category_path(category)
    end
  end

  test "another user's category is not reachable" do
    delete category_path(categories(:ops))

    assert_redirected_to root_path
    assert_equal Category.exists?(categories(:ops).id), true
  end
end
