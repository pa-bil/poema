class CreateViewcounters < ActiveRecord::Migration
  def up
    create_table :view_counters, :id => false do |t|
      t.references  :viewcountable, :polymorphic => true, :null => false
      t.integer     :counter, :default => 0, :null => false
    end
    execute "ALTER TABLE view_counters ADD PRIMARY KEY (viewcountable_id, viewcountable_type)"
  end

  def down

  end
end
