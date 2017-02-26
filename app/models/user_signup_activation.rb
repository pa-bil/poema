class UserSignupActivation < ActiveRecord::Base
  belongs_to :user

  def perform_signup(ip)
    self.code =  SecureRandom.base64(128).gsub(/[^0-9a-z ]/i, '').slice(0..32)
    self.signup_on = Time.zone.now
    self.signup_ip = request.remote_ip
    self.save!
  end

  def perform_activation(ip)
    raise Poema::Exception::SignupActivationAlreadyActive.new unless self.activation_on.nil?
    user = self.user
    user.locked = false
    user.save!
    self.activation_on = Time.zone.now
    self.activation_ip = ip
    self.save!
  end

end
