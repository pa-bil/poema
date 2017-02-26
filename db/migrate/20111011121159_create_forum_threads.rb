class CreateForumThreads < ActiveRecord::Migration
  def change
    create_table :forum_threads do |t|
      t.references  :forum,               :null => false
      t.references  :user,                :null => false

      t.string      :title,               :null => false, :limit => 254
      t.text        :content,             :null => false

      t.integer     :counter_post,        :null => false, :default => 0
      t.datetime    :last_post,           :null => false                      # na początku to data dodania

      t.boolean     :banned,              :null => false, :default => false   # zbanowane wątki znikają z listy
      t.boolean     :closed,              :null => false, :default => false
      t.boolean     :sticky,              :null => false, :default => false

      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :forum_threads, [:id, :deleted_at]
    add_index :forum_threads, [:forum_id, :banned, :deleted_at], :name => 'forum_threads_f_b_da'
    add_index :forum_threads, [:user_id, :deleted_at], :name => 'forum_threads_u_da'

    add_foreign_key(:forum_threads, :forums)
    add_foreign_key(:forum_threads, :users)

    # id ostatnio uaktualnionego wątku w danym forum
    add_foreign_key(:forums, :forum_threads, :column => 'last_forum_thread_id')

    ContentObject.find_or_create_by_id(ForumThread.name)
  end
end
