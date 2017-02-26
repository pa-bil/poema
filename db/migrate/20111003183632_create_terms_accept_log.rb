class CreateTermsAcceptLog < ActiveRecord::Migration
  def up
    # Wersje regulaminu
    create_table :terms_accept_logs do |t|

      t.references :user,           :null => false
      t.references :terms_version,  :null => false
      t.boolean    :accepted        # null: nie ruszone, true, false
      t.timestamps
    end

    add_index(:terms_accept_logs, [:user_id, :terms_version_id], :unique => true)

    add_foreign_key(:terms_accept_logs, :users)
    add_foreign_key(:terms_accept_logs, :terms_versions)
  end

  def down
  end
end
