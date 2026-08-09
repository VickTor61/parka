module ApplicationHelper
  def navigation_items
    [
      { path: root_path, svg: "house.svg", text: "Home" },
      { path: categories_path, svg: "tag.svg", text: "Categories" },
      { path: plans_path, svg: "target.svg", text: "Plans" },
      { path: actuals_path, svg: "wallet.svg", text: "Actuals" },
      { path: reports_path, svg: "chart.svg", text: "Report" },
      { path: locks_path, svg: "lock.svg", text: "Locks" },
      { path: settings_api_tokens_path, svg: "settings.svg", text: "Settings" }
    ]
  end

  def pagination_link(text, page)
    classes = "rounded-md border border-gray-200 px-2.5 py-1.5 text-sm font-medium shadow-sm"

    if page
      link_to text, url_for(request.query_parameters.merge(page: page, only_path: true)), class: "#{classes} text-gray-700 hover:bg-gray-100", data: { turbo_action: "replace" }
    else
      tag.span(text, class: "#{classes} cursor-not-allowed text-gray-400")
    end
  end

  def hidden_query_fields(except: [], params_hash: nil, prefix: nil)
    source = params_hash || request.query_parameters.except(*Array(except))

    safe_join(source.flat_map do |key, value|
      name = prefix ? "#{prefix}[#{key}]" : key.to_s

      if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
        hidden_query_fields(params_hash: value.to_h, prefix: name)
      else
        hidden_field_tag(name, value, id: nil)
      end
    end)
  end

  def active_nav?(path)
    return false if path == "#"
    return true if current_page?(path)
    return false if path == root_path

    request.path.start_with?(path)
  end
end
