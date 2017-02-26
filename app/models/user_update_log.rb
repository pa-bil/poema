class UserUpdateLog < ActiveRecord::Base
  belongs_to :user

  def self.list_by_user(user)
    user.user_update_logs.order("created_at DESC").to_a
  end

  def self.destroy_all_owned_by(user)
    user.user_update_logs.each do |entry|
      entry.destroy
    end
  end
end
