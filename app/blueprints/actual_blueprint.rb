class ActualBlueprint < Blueprinter::Base
  identifier :id

  field :month, &:month_label
  field(:amount) { |actual| actual.amount.to_s }
  field :note
  field(:locked) { |actual, options| options[:locked_months].to_a.include?(actual.month) }

  association :category, blueprint: CategoryBlueprint, view: :nested

  fields :created_at, :updated_at
end
