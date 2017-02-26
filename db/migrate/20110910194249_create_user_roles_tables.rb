# encoding: utf-8

class CreateUserRolesTables < ActiveRecord::Migration
  def up

    # Definicje grup autoryzacji (Role z acl9)
    create_table :roles do |t|
      t.string     :name,              :limit => 64,  :null => false
      t.string     :authorizable_type, :limit => 40
      t.integer    :authorizable_id
      t.string     :description,       :limit => 254
      t.timestamps
    end

    add_index :roles, [:name, :authorizable_id, :authorizable_type], :unique => true

    create_table :roles_users, :id => false do |t|
      t.references  :user
      t.references  :role
    end

    add_index :roles_users, [:user_id, :role_id], :unique => true
    add_foreign_key :roles_users, :users
    add_foreign_key :roles_users, :roles
  end

  def down
  end
end
