module ApplicationHelper
  def navigation_items
    [
      { path: root_path, svg: "house.svg", text: "Overview" }
    ]
  end

  def active_nav?(path)
    return false if path == "#"
    return true if current_page?(path)
    return false if path == root_path

    request.path.start_with?(path)
  end
end
