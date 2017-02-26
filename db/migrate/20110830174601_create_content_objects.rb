# encoding: utf-8
class CreateContentObjects < ActiveRecord::Migration
  def up
    create_table :content_objects, :id => false do |t|
      t.string     :id,            :null => false, :limit => 64
      t.text       :description
      t.timestamps
    end
    execute "ALTER TABLE content_objects ADD PRIMARY KEY (id)"
  end

  def down
  end
end
