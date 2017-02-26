class CreateAudits < ActiveRecord::Migration
  def change
    create_table :audits, :id => false do |t|
      t.references  :auditable,  :polymorphic => true
      t.integer     :event_type, :null => false, :limit => 1
      t.integer     :level,      :null => false, :limit => 1, :default => Audit::LEVEL_INFO
      t.references  :user
      t.string      :ip,         :limit => 254
      t.text        :description

      t.timestamps
    end
    
    add_index :audits, [:auditable_type, :auditable_id]
    add_index :audits, :user_id
    add_index :audits, :event_type
    add_index :audits, :level    
    
    add_foreign_key :audits, :users
  end
end
