class CreateContentCopyrights < ActiveRecord::Migration
  def up
    create_table :content_copyrights do |t|
      t.string      :title,               :null => false, :limit => 254
      t.text        :description
      t.boolean     :prohibit_exposition, :null => false, :default => false
      t.timestamps
    end
        
    add_index :content_copyrights, :prohibit_exposition

    ContentCopyright.create :id => 1, :title => "misc.copyright.notset"
    ContentCopyright.create :id => 2, :title => "misc.copyright.dontknow"
    ContentCopyright.create :id => 3, :title => "misc.copyright.owner"
    ContentCopyright.create :id => 4, :title => "misc.copyright.publicdomain"
    ContentCopyright.create :id => 5, :title => "misc.copyright.permitted"
    ContentCopyright.create :id => 6, :title => "misc.copyright.notpermitted", :prohibit_exposition => true
  end

  def down
  end
end
