class CreateActuals < ActiveRecord::Migration[8.1]
  def change
    create_table :actuals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false
      t.date :month, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :note

      t.timestamps
    end

    add_index :actuals, [ :user_id, :category_id, :month ]
    add_index :actuals, [ :user_id, :month ]

    add_foreign_key :actuals, :categories, column: [ :category_id, :user_id ], primary_key: [ :id, :user_id ]

    add_check_constraint :actuals, "extract(day from month) = 1", name: "actuals_month_is_first_of_month"
  end
end
