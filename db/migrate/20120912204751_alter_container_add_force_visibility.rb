class AlterContainerAddForceVisibility < ActiveRecord::Migration
  def up
    add_column :containers, :force_visibility, :bool, :null => false, :default => false

    # FYI: drop i create w różnych zapytaniach naruszają relacje, to powinno iść jako pojedyncze zapytanie
    execute "ALTER TABLE `containers` DROP INDEX `containers_c_b_v_cp_da`,
             ADD INDEX `containers_c_b_v_cp_fv_da` (`container_id`, `banned`, `visible`, `counter_publication`, `force_visibility`, `deleted_at`);"
  end

  def down
  end
end
