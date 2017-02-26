# encoding: utf-8
class CreateStatcounters < ActiveRecord::Migration
  def change
    create_table :stat_counter_objects do |t|
      t.string      :handle,                    :null => false, :limit => 32
      t.string      :description,               :limit => 254
      t.string      :color,                     :limit => 16
      t.float       :multiplier,                :null => false, :default => 1

      t.timestamps
    end
    
    add_index :stat_counter_objects, :handle, :unique => true
    
    create_table :stat_counters, :id => false do |t|
      t.references :stat_counter_object,        :null => false
      t.date       :date,                       :null => false
      t.integer    :counter,                    :null => false, :default => 0
    end

    execute "ALTER TABLE stat_counters ADD PRIMARY KEY (stat_counter_object_id, date)"
    add_foreign_key(:stat_counters, :stat_counter_objects)
    
    StatCounterObject.create :handle => "signup", 
                             :description => "Konta użytkowników, które przybyły w danym okresie czasu", 
                             :color => "#008000", :multiplier => 1
    StatCounterObject.create :handle => "login", 
                             :description => "Ilość logowań użytkowników", 
                             :color => "#66ff33", :multiplier => 1
    StatCounterObject.create :handle => "publication",  
                             :description => "Ilość nowych publikacji", 
                             :color => "#ff9900", :multiplier => 1
    StatCounterObject.create :handle => "comment",      
                             :description => "Ilość dodanych komentarzy", 
                             :color => "#9966cc", :multiplier => 1
    StatCounterObject.create :handle => "view",         
                             :description => "Ilość odsłon stron serwisu, publikacji, kontenerów, etc.", 
                             :color => "#3399ff", :multiplier => 0.01
  end
end
