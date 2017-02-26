class SessionLoginForm  < ActiveForm
  attr_accessor :password, :login, :user, :auth

  validates_with UserValidator, :allow_banned => true, :error_key => :login
  validates_with AuthCorrectPasswordValidator
end
