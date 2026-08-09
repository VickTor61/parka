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

  def pagination_link(text, page)
    classes = "rounded-md border border-gray-200 px-2.5 py-1.5 text-sm font-medium shadow-sm"

    if page
      link_to text, url_for(request.query_parameters.merge(page: page, only_path: true)), class: "#{classes} text-gray-700 hover:bg-gray-100"
    else
      tag.span(text, class: "#{classes} cursor-not-allowed text-gray-400")
    end
  end

  def active_nav?(path)
    return false if path == "#"
    return true if current_page?(path)
    return false if path == root_path

    request.path.start_with?(path)
  end
end
