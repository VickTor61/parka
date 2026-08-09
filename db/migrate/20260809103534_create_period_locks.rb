class CreatePeriodLocks < ActiveRecord::Migration[8.1]
  def change
    create_table :period_locks do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month, null: false

      t.timestamps
    end

    add_index :period_locks, [ :user_id, :month ], unique: true

    add_check_constraint :period_locks, "extract(day from month) = 1", name: "period_locks_month_is_first_of_month"
  end
end
