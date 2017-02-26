class CreateUserRanks < ActiveRecord::Migration
  def change
    create_table :user_ranks do |t|
      t.integer :rank, :null => false, :default => 0
      t
    end
    add_foreign_key(:user_ranks, :users, {:column => 'id'})
  end
end
