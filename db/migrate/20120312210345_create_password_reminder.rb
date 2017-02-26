class CreatePasswordReminder < ActiveRecord::Migration
  def change
    create_table :password_reminders do |t|
      t.references       :user,         :null => false
      t.string           :email,        :null => false, :limit => 254
      t.string           :token,        :null => false, :limit => 254
      t.datetime         :completed_at

      t.timestamps
    end

    add_index(:password_reminders, :token, :unique => true)

    add_index(:password_reminders, [:token, :completed_at])
    add_index(:password_reminders, [:user_id, :created_at])

    add_foreign_key(:password_reminders, :users)
  end
end
