class MoneyDonationAction < ActiveRecord::Base
  attr_accessible :info_url, :money_donated, :money_target, :year
end
