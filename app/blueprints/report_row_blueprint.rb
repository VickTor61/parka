class ReportRowBlueprint < Blueprinter::Base
  field(:category) { |row| { id: row.category_id, name: row.category_name } }
  field(:month) { |row| row.month.strftime(MonthlyPeriod::FORMAT) }
  field(:plan) { |row| row.plan.to_s }
  field(:actual) { |row| row.actual&.to_s }
  field(:variance) { |row| row.variance&.to_s }
  field(:variance_percentage) { |row| row.variance_percentage&.round(2)&.to_s }
  field(:reported) { |row| row.reported? }
  field(:entries_count) { |row| row.entries_count.to_i }
  field(:locked) { |row, options| options[:locked_months].to_a.include?(row.month) }
end
