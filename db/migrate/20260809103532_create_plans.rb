class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false
      t.date :month, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false

      t.timestamps
    end

    add_index :plans, [ :user_id, :category_id, :month ], unique: true
    add_index :plans, [ :user_id, :month ]

    add_foreign_key :plans, :categories, column: [ :category_id, :user_id ], primary_key: [ :id, :user_id ]

    add_check_constraint :plans, "extract(day from month) = 1", name: "plans_month_is_first_of_month"
    add_check_constraint :plans, "amount >= 0", name: "plans_amount_not_negative"
  end
end
