class ChangeDefaultsForContentCopyright < ActiveRecord::Migration
  def change
    [:uploaded_files, :publications].each do |table|
      change_column table, :content_copyright_id, :integer, :default => 1, :null => false
    end
  end
end
