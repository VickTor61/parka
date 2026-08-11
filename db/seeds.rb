# Seeds a demo account with the sample data from the assignment brief.
# Idempotent — safe to run again; existing records are left untouched.
#
#   bin/rails db:seed
#
# Demo login (development only):
#   email: demo@example.com
#   password: password123
# The report for FY 2026 reproduces the sample variance table from the brief
# (Marketing Feb is intentionally unreported and renders as "—").

demo = User.find_or_create_by!(email_address: "demo@example.com") do |user|
  user.password = "password123"
end

category_names = [
  "Marketing",
  "Payroll",
  "Operations",
  "Sales",
  "Technology",
  "Human Resources",
  "Facilities",
  "Legal",
  "Finance",
  "Customer Support"
]
categories = category_names.to_h { |name| [ name.downcase.tr(" ", "_"), demo.categories.find_or_create_by!(name: name) ] }

marketing = categories.fetch("marketing")
payroll = categories.fetch("payroll")

sample_plans = [
  [ marketing, "2026-01", 5_000 ],
  [ marketing, "2026-02", 5_000 ],
  [ payroll, "2026-01", 20_000 ],
  [ payroll, "2026-02", 20_000 ],
  [ categories.fetch("operations"), "2026-01", 12_000 ],
  [ categories.fetch("sales"), "2026-01", 15_000 ],
  [ categories.fetch("technology"), "2026-01", 18_000 ],
  [ categories.fetch("human_resources"), "2026-01", 8_000 ],
  [ categories.fetch("facilities"), "2026-01", 6_000 ],
  [ categories.fetch("legal"), "2026-01", 4_000 ],
  [ categories.fetch("finance"), "2026-01", 7_000 ],
  [ categories.fetch("customer_support"), "2026-01", 9_000 ]
]

sample_actuals = [
  [ marketing, "2026-01", 4_800, "Q1 ad campaign" ],
  [ payroll, "2026-01", 20_500, nil ],
  [ payroll, "2026-02", 19_800, nil ],
  [ categories.fetch("operations"), "2026-01", 11_500, nil ],
  [ categories.fetch("sales"), "2026-01", 15_300, nil ],
  [ categories.fetch("technology"), "2026-01", 17_400, "Cloud hosting" ],
  [ categories.fetch("human_resources"), "2026-01", 7_800, nil ],
  [ categories.fetch("facilities"), "2026-01", 6_200, nil ],
  [ categories.fetch("legal"), "2026-01", 3_750, nil ],
  [ categories.fetch("finance"), "2026-01", 6_900, nil ],
  [ categories.fetch("customer_support"), "2026-01", 8_800, nil ]
]

sample_plans.each do |category, month, amount|
  plan = demo.plans.find_or_initialize_by(category: category, month: MonthlyPeriod.cast(month))
  plan.amount = amount
  plan.save!
end

sample_actuals.each do |category, month, amount, note|
  actual = demo.actuals.find_or_initialize_by(category: category, month: MonthlyPeriod.cast(month), amount: amount)
  actual.note = note
  actual.save!
end

puts <<~MESSAGE

  Seeded the demo account:
    email:    demo@example.com
    password: password123

  Report → all of FY 2026 shows the sample variance table (Marketing Feb is "—").
MESSAGE
