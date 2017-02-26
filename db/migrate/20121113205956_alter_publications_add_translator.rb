class AlterPublicationsAddTranslator < ActiveRecord::Migration
  def up
    add_column :publications, :translator, :string, :null => true, :default => nil, :limit => 128
    ContentCopyright.create :id => 7, :title => "misc.copyright.translation_owner"
  end

  def down
  end
end
