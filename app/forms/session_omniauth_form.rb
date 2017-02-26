class SessionOmniauthForm < ActiveForm
  attr_accessor :user, :auth

  validates_with UserValidator, :allow_banned => true
end
