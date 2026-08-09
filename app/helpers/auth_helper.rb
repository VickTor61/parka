module AuthHelper
  def auth_label_class
    "block text-sm leading-snug tracking-tight text-stone-700"
  end

  def auth_input_class
    "block w-full rounded-lg bg-white px-2.5 py-2 text-sm text-stone-700 shadow-sm outline-1 -outline-offset-1 outline-stone-200 placeholder:text-stone-300 focus:outline-2 focus:-outline-offset-2 focus:outline-stone-950"
  end

  def auth_button_class
    "w-full cursor-pointer rounded-lg bg-stone-950 px-3 py-1.5 text-sm font-semibold text-white shadow-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-black"
  end

  def auth_link_class
    "text-sm tracking-tight text-stone-950"
  end
end
