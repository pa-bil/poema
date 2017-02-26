class DictCountry < ActiveRecord::Base
  has_many :dict_cities
  has_many :dict_provinces
end
