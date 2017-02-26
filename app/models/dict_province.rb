class DictProvince < ActiveRecord::Base
  has_many :dict_cities
  belongs_to :dict_country
end
