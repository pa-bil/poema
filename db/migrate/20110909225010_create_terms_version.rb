# encoding: utf-8

class CreateTermsVersion < ActiveRecord::Migration
  def up
    # Wersje regulaminu
    create_table :terms_versions do |t|
      t.boolean    :current,     :null => false, :default => false
      t.datetime   :introduced,  :null => false
      t.datetime   :expired
      t.text       :description
      t.timestamps
    end

    add_index(:terms_versions, :current)

    TermsVersion.create :id => 1, :current => true,  :introduced => '2000-11-27 00:00:00', :description => 'Regulamin'
  end

  def down
  end
end
