class PasswordReminder < ActiveRecord::Base
  acts_as_auditable

  belongs_to :user

  validates_with UserIdValidator, :allow_banned => true
  validates_with EmailValidator

  validate  :check_create
  validate  :check_destroy

  attr_accessible :email

  before_validation :find_user
  before_create :generate_token

  protected

  def find_user
    unless self.email.nil?
      self.user = User.find_by_email(self.email)

      # Jeśli nic się nie znalazło moglibyśmy szukać w changelogu adresów email, przy czym dopóty nie
      # powstanie ficzer umożliwiający potwierdzenie zmian adresu nie możemy tak robić, user mógłby
      # sobie poustawiać jakieś znane adresy, później namówić tych ludzi do założenia konta i pozyskać
      # ich hasła
      #
      #if u.nil?
      #  unless (r = UserUpdateLog.where(:field_name => 'email', :value => self.email).order("created_at DESC").limit(1)).to_a.empty?
      #    u = r.first.user
      #  end
      #end
    end

  end

  def check_create
    if self.new_record?
      if self.user && self.user.password_reminders.where('created_at > DATE_SUB(NOW(), INTERVAL 1 DAY)').count > 0
        errors.add(:email, :wait_24_h)
      end
    end
  end

  def check_destroy
    unless self.new_record?
      errors.add(:email, :token_expired) if (self.created_at + 24.hours) < Time.zone.now
      errors.add(:email, :token_taken) unless self.class.find(self.id).completed_at.nil?
    end
  end

  def generate_token
    raise "Token can be generated only once" unless self.new_record?
    self.token = SecureRandom.base64(128).gsub(/[^0-9a-z ]/i, '').slice(1..64)
  end
end
