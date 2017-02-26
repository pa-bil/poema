class CreateForums < ActiveRecord::Migration
  def up
    create_table :forums do |t|
      t.string    :title,                 :null => false, :limit => 254
      t.text      :description

      t.boolean   :banned,                :null => false, :default => false
      t.boolean   :visible,               :null => false, :default => true

      t.boolean   :moderated,             :null => false, :default => false
      t.boolean   :allow_html,            :null => false, :default => false

      t.datetime  :last_post,             :null => false
      t.integer   :counter_post,          :null => false, :default => 0

      t.integer   :last_forum_thread_id

      t.datetime  :deleted_at
      t.timestamps
    end

    add_index :forums, [:id, :deleted_at]
    add_index :forums, [:banned, :visible, :deleted_at], :name => 'forums_b_v_da'

    ContentObject.find_or_create_by_id(Forum.name)
  end
end
