# encoding: utf-8
# Tabele słowników krajów, województw, miast

class CreateDictLocalisation < ActiveRecord::Migration

  def load_from_dump(file)
    dir = File.dirname(__FILE__)
    sql = ""
    source = File.new("#{dir}/sql/#{file}", "r")
    while (line = source.gets)
      sql << line
    end
    source.close
    execute sql
  end

  def up
    create_table :dict_countries do |t|
      t.string     :country,                 :null => false, :limit => 254
      t.string     :code,                    :null => false, :limit => 2
      t.timestamps
    end

    add_index(:dict_countries, :code, :unique => true)
    load_from_dump "dict_countries.sql"

    create_table :dict_provinces do |t|
      t.references :dict_country,             :null => false
      t.string     :province,                 :null => false, :limit => 254
      t.timestamps
    end

    add_foreign_key(:dict_provinces, :dict_countries)
    load_from_dump "dict_provinces.sql"
    
    create_table :dict_cities do |t|
      t.references :dict_country,            :null => false
      t.references :dict_province
      t.string     :city,                    :null => false, :limit => 254
      t.timestamps
    end

    add_foreign_key(:dict_cities, :dict_countries)
    add_foreign_key(:dict_cities, :dict_provinces)
    load_from_dump "dict_cities.sql"
  end

  def down
  end
end
