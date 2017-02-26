class CreateContainers < ActiveRecord::Migration
  def up
    create_table :containers do |t|
      t.references  :container
      t.references  :user,                          :null => false

      t.string      :title,                         :null => false, :limit => 254
      t.text        :intro
      t.text        :description      

      t.integer     :sort,                          :null => false, :default => 0
      t.integer     :order_key

      t.boolean     :banned,                        :null => false, :default => false
      t.boolean     :visible,                       :null => false, :default => true
      
      t.string      :allow_comments,                :null => false, :default => 'D', :limit => 1
      
      t.integer     :avatar_uploaded_file_id

      t.integer     :granted_container_creator_role_id
      t.integer     :granted_publication_creator_role_id

      t.integer     :counter_publication,           :null => false, :default => 0
      t.integer     :counter_container,             :null => false, :default => 0

      t.datetime    :last_publication

      # commentable
      t.datetime    :last_comment                   # data otrzymania ostatniego komentarza
      t.integer     :counter_comment_neutral,       :null => false, :default => 0
      t.integer     :counter_comment_positive,      :null => false, :default => 0
      t.integer     :counter_comment_negative,      :null => false, :default => 0

      t.datetime    :deleted_at
      t.timestamps
    end

    add_index :containers, [:id, :deleted_at]

    add_index :containers, [:container_id, :banned, :visible, :counter_publication, :deleted_at], :name => 'containers_c_b_v_cp_da'
    add_index :containers, [:id, :banned, :visible, :deleted_at], :name => 'containers_id_b_v_da'
    add_index :containers, [:user_id, :deleted_at], :name => 'containers_u_da'

    add_foreign_key(:containers, :containers)
    add_foreign_key(:containers, :users)

    add_foreign_key(:containers, :roles, :column => 'granted_container_creator_role_id')
    add_foreign_key(:containers, :roles, :column => 'granted_publication_creator_role_id')

    ContentObject.find_or_create_by_id(Container.name)

    # Ta tabela będzie utworzona przez migrację, nie mniej jednak potrzebuję jej definicji juz teraz
    execute "CREATE TABLE IF NOT EXISTS migration_sec_container_map (sec_id INT(10), container_id INT(10))
      COLLATE='utf8_polish_ci'
      ENGINE=InnoDB"
  end
  
  def down
  end
end
