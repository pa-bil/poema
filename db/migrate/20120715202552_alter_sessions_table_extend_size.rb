class AlterSessionsTableExtendSize < ActiveRecord::Migration
  def up
    # to jest potrzebne do ewentualnego trzymania w sesji plików, na produkcji sesja i tak pójdzie do
    # memcache
    change_table :sessions do |t|
      t.change :data, :text, :limit => 4294967295
    end
  end
end
