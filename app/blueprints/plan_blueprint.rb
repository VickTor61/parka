class PlanBlueprint < Blueprinter::Base
  identifier :id

  field :month, &:month_label
  field(:amount) { |plan| plan.amount.to_s }
  field(:locked) { |plan, options| options[:locked_months].to_a.include?(plan.month) }

  association :category, blueprint: CategoryBlueprint, view: :nested

  fields :created_at, :updated_at
end
