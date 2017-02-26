class CreateUserStats < ActiveRecord::Migration
  def up
    create_table :user_stats do |t|
      t.references  :user,                        :null => false

      t.datetime    :current_visit
      t.datetime    :last_visit

      t.datetime    :last_publication
      t.datetime    :last_commented               # data wystawienia ostatniego komentarza przez użytkownika do dowolnego obiektu
      t.datetime    :last_forum_post

      t.integer     :counter_publication,         :null => false, :default => 0
      t.integer     :counter_container,           :null => false, :default => 0
      t.integer     :counter_forum_post,          :null => false, :default => 0

      t.integer     :counter_commented_neutral,   :null => false, :default => 0
      t.integer     :counter_commented_positive,  :null => false, :default => 0
      t.integer     :counter_commented_negative,  :null => false, :default => 0

      t.datetime    :deleted_at
      t.timestamps
    end

    add_index(:user_stats, [:id, :deleted_at])
    add_index(:user_stats, [:user_id, :deleted_at])
    add_foreign_key(:user_stats, :users)
  end
end
