class AlterSpecialActonsAddNotify < ActiveRecord::Migration
  def up
    add_column :special_actions, :send_notification, :bool, :null => false, :default => false
  end

  def down
  end
end
