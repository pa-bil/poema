class CreateMoneyDonationActions < ActiveRecord::Migration
  def change
    create_table :money_donation_actions do |t|
      t.integer :money_donated
      t.integer :money_target
      t.string  :info_url
      t.integer :year

      t.timestamps
    end
  end
end
