class CreateComments < ActiveRecord::Migration
  def up
    create_table :comments do |t|

      # user może być null (vide komenty anonimowe)
      t.references  :user,              :null => true
      t.references  :commentable,       :polymorphic => true, :null => false

      t.string      :name,              :limit => 254
      t.string      :email,             :limit => 100

      t.text        :content,           :null => false
      t.integer     :emotion,           :null => false, :limit => 1

      t.boolean     :banned,            :null => false, :default => false # zbanowane komentarze pokazujemy na liście

      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :comments, [:commentable_id, :commentable_type, :deleted_at], :name => 'comments_cid_ct_da'
    add_index :comments, [:user_id, :deleted_at],                           :name => 'comments_ui_da'

    add_foreign_key :comments, :users
    add_foreign_key :comments, :content_objects, :column => :commentable_type
  end

  def down

  end
end
