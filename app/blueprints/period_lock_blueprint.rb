class PeriodLockBlueprint < Blueprinter::Base
  identifier :id

  field :month, &:month_label
  field :created_at
end
