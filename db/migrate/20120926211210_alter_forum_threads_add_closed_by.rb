class AlterForumThreadsAddClosedBy < ActiveRecord::Migration
  def up
    add_column :forum_threads, :closed_by_user_id, :integer, :null => true, :default => nil
    add_foreign_key(:forum_threads, :users, :column => 'closed_by_user_id')

    magic_date = '2012-09-07 21:45:50'

    # wątki poniżej magicznej daty migracji zamykamy jako root (1) - te wątki zamykane były z powodów
    # administracyjnych
    ForumThread.where(:closed => true).where("created_at < ?", magic_date).each do |t|
      t.update_column :closed_by_user_id, 1
    end

    # wątki powyżej daty migracji zamykamy jako owner, to pozwoli ownerom odpowiadać sobie na nie
    ForumThread.where(:closed => true).where("created_at >= ?", magic_date).each do |t|
      t.update_column :closed_by_user_id, t.owner.id
    end
  end

  def down
  end
end
