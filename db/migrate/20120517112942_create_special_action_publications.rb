class CreateSpecialActionPublications < ActiveRecord::Migration
  def change 
    create_table      :special_action_publications do |t|    
      t.references    :special_action,   :null => false
      t.references    :publication,      :null => false                 
      t.timestamps
    end
    
    add_foreign_key(:special_action_publications, :special_actions)
    add_foreign_key(:special_action_publications, :publications)
  end
end
