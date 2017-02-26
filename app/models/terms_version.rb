class TermsVersion < ActiveRecord::Base
  has_many :users
  has_many :terms_accept_logs

  def self.current
    self.find_by_current(1)
  end

  def self.current!
    self.find_by_current!(1)
  end
end
