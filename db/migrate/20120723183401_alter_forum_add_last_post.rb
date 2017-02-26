class AlterForumAddLastPost < ActiveRecord::Migration
  def change
    rename_column :forums, :last_post, :last_activity_at
    rename_column :forum_threads, :last_post, :last_activity_at

    execute "ALTER TABLE forum_threads ADD COLUMN last_forum_post_id INTEGER NULL
          AFTER last_activity_at"

    # ID ostatnio uaktualnionego postu w danym wątku
    add_foreign_key(:forum_threads, :forum_posts, :column => 'last_forum_post_id')
  end
end
