# encoding: utf-8

class CreateUploadedFiles < ActiveRecord::Migration
  def up

    # Upload plików, tabela poema_quota
    create_table :uploaded_files do |t|

      t.references  :user,                   :null => false

      t.references  :uploadable,             :polymorphic => true, :null => false

      t.string      :file_file_name,         :null => false, :limit => 254
      t.string      :file_content_type,      :null => false, :limit => 64
      t.integer     :file_file_size,         :null => false
      t.datetime    :file_updated_at

      t.text        :description
      t.references  :content_copyright,     :null => false

      t.datetime    :last_commented

      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :uploaded_files, [:uploadable_id, :uploadable_type, :deleted_at],   :name => 'uploaded_files_uid_ut_da'
    add_index :uploaded_files, [:user_id, :deleted_at],                           :name => 'uploaded_files_ui_da'

    add_foreign_key :uploaded_files, :users
    add_foreign_key :uploaded_files, :content_copyrights
    add_foreign_key :uploaded_files, :content_objects, :column => :uploadable_type
  end

  def down
  end
end
