class CreateUserBlacklists < ActiveRecord::Migration
  def change
    create_table :user_blacklists do |t|
      t.references  :user,                  :null => false
      t.integer     :blacklisted_user_id,   :null => false
      t.string      :reason,                :null => true, :default => nil, :limit => 254
      t.timestamps
    end

    add_index :user_blacklists, [:user_id, :blacklisted_user_id], :unique => true

    add_foreign_key :user_blacklists, :users
    add_foreign_key :user_blacklists, :users, :column => :blacklisted_user_id
  end
end
