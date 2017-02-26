# encoding: utf-8
module UserBlacklistHelper
  def user_blacklist_allowed?(owner, user)
    if !owner || !user || user.anonymous? || owner == user
      false
    else
      true
    end
  end
end
