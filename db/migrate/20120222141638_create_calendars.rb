class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.references :user,                       :null => false

      t.string     :title,                      :null => false, :limit => 254
      t.text       :description
      t.string     :link,                       :limit => 254

      t.date       :start_date,                 :null => false
      t.time       :start_time
      t.date       :finish_date
      t.time       :finish_time

      t.string     :localisation,               :null => false, :limit => 1024
      t.string     :localisation_geocoder,      :limit => 1024
      t.float      :longitude
      t.float      :latitude

      t.string     :venue,                      :null => false, :limit => 254

      t.integer    :avatar_uploaded_file_id

      t.boolean    :banned,                     :null => false, :default => false
      t.boolean    :visible,                    :null => false, :default => true

      t.boolean    :sticky,                     :null => false, :default => false

      t.datetime   :last_comment
      t.integer    :counter_comment_neutral,    :null => false, :default => 0
      t.integer    :counter_comment_positive,   :null => false, :default => 0
      t.integer    :counter_comment_negative,   :null => false, :default => 0

      t.datetime   :deleted_at
      t.timestamps
    end

    add_index :calendars, [:id, :deleted_at]
    add_index :calendars, [:banned, :visible, :deleted_at], :name => 'calendars_b_v_da'
    add_index :calendars, [:banned, :visible, :deleted_at, :start_date, :finish_date], :name => 'calendars_b_v_da_s_f'

    add_foreign_key(:calendars, :users)

    ContentObject.find_or_create_by_id(Calendar.name)
  end
end
