class AlterPublicationsAddIndexForPublishedAt < ActiveRecord::Migration
  def up
    add_index :publications, [:banned, :visible, :deleted_at, :published_at], :name => 'publications_b_v_da_pa'
  end

  def down
  end
end
