class UserRank < ActiveRecord::Base
  belongs_to :user

  def rank_trusted?
    rank >= 10
  end
end
