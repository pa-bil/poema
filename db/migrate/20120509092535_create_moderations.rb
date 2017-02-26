class CreateModerations < ActiveRecord::Migration
  def change
    create_table :moderations do |t|
    
      t.references :moderateable, :polymorphic => true, :null => false
      
      t.integer    :moderator_id, :null => false
      t.references :user                                            # user może być null, obiekty moga być anonimowe, eg. komentarze
      
      t.text       :reason
      t.text       :complain
      
      t.boolean    :active,       :null => false, :default => true
      t.date       :expiry_date                                     # ekspirowaniem banów zajmuje się osobny skrypt
      
      t.timestamps
    end
    
    add_index :moderations, [:moderateable_id, :moderateable_type], :name => 'moderations_mid_mt'
    
    add_foreign_key :moderations, :users
    add_foreign_key :moderations, :users, :column => :moderator_id
  end
end
