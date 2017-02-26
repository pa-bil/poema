class SearchIndexCreate < ActiveRecord::Migration

  def up
    create_table :search_indices, :options => "ENGINE=MyISAM" do |t|
      t.text       :content,           :limit => 4294967295
      t.references :searchable,        :polymorphic => true, :null => false
      t.timestamps
    end

    add_index :search_indices, [:searchable_id, :searchable_type]
    add_foreign_key :search_indices, :content_objects, :column => :searchable_type

    execute 'CREATE FULLTEXT INDEX fulltext_search_index ON search_indices (content)'
  end

  def down
  end
end
