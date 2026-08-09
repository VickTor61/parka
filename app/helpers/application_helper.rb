module ApplicationHelper
  def navigation_items
    [
      { path: root_path, svg: "house.svg", text: "Home" },
      { path: categories_path, svg: "tag.svg", text: "Categories" },
      { path: plans_path, svg: "target.svg", text: "Plans" },
      { path: actuals_path, svg: "wallet.svg", text: "Actuals" },
      { path: locks_path, svg: "lock.svg", text: "Locks" }
    ]
  end

  def active_nav?(path)
    return false if path == "#"
    return true if current_page?(path)
    return false if path == root_path

    request.path.start_with?(path)
  end
end
