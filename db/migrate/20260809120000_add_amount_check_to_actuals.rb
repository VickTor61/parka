class AddAmountCheckToActuals < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :actuals, "amount >= 0", name: "actuals_amount_not_negative"
  end
end
