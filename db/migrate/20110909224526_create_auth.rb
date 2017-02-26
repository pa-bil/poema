# encoding: utf-8

class CreateAuth < ActiveRecord::Migration
  def up
    create_table :auths do |t|
      t.string     :login,          :limit => 100, :null => false
      t.string     :password,       :limit =>  64
      t.string     :crypt,          :limit =>  32, :null => false
      t.string     :nk_id,          :limit => 128
      t.string     :fb_id,          :limit => 128
      t.integer    :counter_login,  :null  => false, :default => 0

      t.datetime   :deleted_at
      t.timestamps
    end
    add_index(:auths, :login, :unique => true)

    add_index(:auths, [:id,    :deleted_at])
    add_index(:auths, [:login, :deleted_at])
    add_index(:auths, [:nk_id, :deleted_at])
    add_index(:auths, [:fb_id, :deleted_at])
  end

  def down
  end
end
