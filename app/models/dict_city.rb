class DictCity < ActiveRecord::Base
   belongs_to :dict_country
   belongs_to :dict_province
end
