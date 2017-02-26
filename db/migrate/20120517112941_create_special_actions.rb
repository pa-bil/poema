class CreateSpecialActions < ActiveRecord::Migration
  def change
    create_table :special_actions do |t|
      t.string     :title,                               :null => false, :limit => 254
      t.text       :description
      t.string     :promoter_title,                      :null => false, :limit => 254
      t.text       :promoter_description
      t.string     :icon_url,                            :limit => 254
      t.boolean    :visible,                             :null => false, :default => true
      t.integer    :granted_special_action_submitter_id
      
      t.date       :start_date
      t.time       :start_time
      t.date       :finish_date
      t.time       :finish_time

      t.datetime   :deleted_at
      t.timestamps
    end
    
    add_index :special_actions, [:visible, :deleted_at, :start_date, :start_time, :finish_date, :finish_time], :name => 'special_actions_v_da_s_f'    
    add_foreign_key(:special_actions, :roles, :column => 'granted_special_action_submitter_id')
  end
end
