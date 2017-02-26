class AdminUserSearchForm < ActiveForm
  attr_accessor :q
  validates :q, :length => {:minimum => 1, :maximum => 48}
end
