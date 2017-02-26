class CreateUserUpdateLog < ActiveRecord::Migration
  def up
    create_table :user_update_logs do |t|
      t.references :user,           :null => false
      t.string     :field_name,     :null => false, :limit => 64
      t.string     :value,          :null => false, :limit => 254
      t.timestamps
    end

    add_index(:user_update_logs, [:user_id, :field_name])
    add_foreign_key(:user_update_logs, :users)
  end

  def down
  end
end
