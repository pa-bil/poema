class CreatePublications < ActiveRecord::Migration
  def up
    create_table :publications do |t|
      t.references  :container,                 :null => false
      t.references  :user,                      :null => false

      t.string      :title,                     :null => false, :limit => 254
      t.text        :intro
      t.text        :content,                   :limit => 4294967295
      t.string      :author,                    :limit => 128
      t.string      :link,                      :limit => 254
      t.references  :content_copyright,         :null => false

      t.boolean     :banned,                    :null => false, :default => false
      t.boolean     :visible,                   :null => false, :default => true

      t.string      :allow_comments,            :null => false, :default => 'D', :limit => 1

      t.integer     :avatar_uploaded_file_id

      # commentable
      t.datetime    :last_comment               # data otrzymania ostatniego komentarza
      t.integer     :counter_comment_neutral,   :null => false, :default => 0
      t.integer     :counter_comment_positive,  :null => false, :default => 0
      t.integer     :counter_comment_negative,  :null => false, :default => 0

      t.datetime    :published_at
      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :publications, [:id, :deleted_at]
    add_index :publications, [:container_id, :banned, :visible, :deleted_at], :name => 'publications_c_b_v_da'
    add_index :publications, [:user_id,      :banned, :visible, :deleted_at], :name => 'publications_u_b_v_da'
    add_index :publications, [:id,           :banned, :visible, :deleted_at], :name => 'publications_i_b_v_da'

    add_index :publications, [:user_id, :deleted_at], :name => 'publications_u_da'

    add_foreign_key :publications, :containers
    add_foreign_key :publications, :users
    add_foreign_key :publications, :content_copyrights

    ContentObject.find_or_create_by_id(Publication.name)
  end

  def down
  end
end
