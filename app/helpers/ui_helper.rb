module UiHelper
  def primary_button_class
    "inline-flex cursor-pointer items-center gap-1.5 rounded-md bg-gray-900 px-2.5 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-gray-700"
  end

  def secondary_button_class
    "inline-flex cursor-pointer items-center gap-1.5 rounded-md border border-gray-200 bg-white px-2.5 py-2 text-sm font-medium text-gray-900 shadow-sm transition-colors hover:bg-gray-100"
  end

  def field_class
    "block w-full rounded-lg bg-white px-2.5 py-2 text-sm text-gray-900 shadow-sm outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-gray-900"
  end

  def field_label_class
    "mb-1.5 block text-sm text-gray-700"
  end

  def money(amount)
    number_to_currency(amount, unit: "$", precision: 2)
  end

  def month_label(date)
    date&.strftime("%b %Y")
  end

  def lock_badge(locked)
    if locked
      tag.span(class: "inline-flex items-center gap-1 rounded-lg bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700") do
        inline_svg_tag("lock.svg", class: "size-3") + "Locked"
      end
    else
      tag.span("Open", class: "inline-flex items-center rounded-lg bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700")
    end
  end

  def blank_cell
    tag.span("—", class: "text-gray-400")
  end

  def signed_money(amount)
    return blank_cell if amount.nil?

    "#{'+' if amount.positive?}#{money(amount)}"
  end

  def signed_percentage(value)
    return blank_cell if value.nil?

    "#{'+' if value.positive?}#{number_to_percentage(value, precision: 2)}"
  end

  def quarter_ranges(year)
    (1..4).map do |quarter|
      first = Date.new(year, (quarter * 3) - 2, 1)

      { label: "Q#{quarter}", from: first.strftime(MonthlyPeriod::FORMAT), to: (first + 2.months).strftime(MonthlyPeriod::FORMAT) }
    end
  end

  def variance_class(amount)
    return "text-gray-500" if amount.nil? || amount.zero?

    amount.negative? ? "text-emerald-700" : "text-red-600"
  end
end
