class CreateForumPosts < ActiveRecord::Migration
  def up
    create_table :forum_posts do |t|
      t.references  :user,          :null => false
      t.references  :forum_thread,  :null => false

      t.references  :forum_post,    :null => true                       # referencja do postu, na którego jestem odpowiedzią

      t.text        :content,       :null => false

      t.boolean     :banned,        :null => false, :default => false   # zbanowane posty pokazujemy na liście

      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :forum_posts, [:id, :deleted_at]

    # w tym indeksie nie ma banned, te posty pokazujemy na liście, jako zablokowane
    add_index :forum_posts, [:forum_thread_id, :deleted_at], :name => 'forum_post_t_da'

    add_index :forum_posts, [:forum_post_id, :deleted_at], :name => 'forum_post_p_da'
    add_index :forum_posts, [:user_id, :deleted_at], :name => 'forum_post_u_da'

    add_foreign_key(:forum_posts, :users)
    add_foreign_key(:forum_posts, :forum_threads)
    add_foreign_key(:forum_posts, :forum_posts)

    ContentObject.find_or_create_by_id(ForumPost.name)
  end
end
