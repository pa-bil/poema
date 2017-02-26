class UserBlacklist < ActiveRecord::Base

  nilify_blanks
  acts_as_auditable

  belongs_to  :owner,       :class_name => 'User', :foreign_key => :user_id
  belongs_to  :blacklisted, :class_name => 'User', :foreign_key => :blacklisted_user_id

  attr_accessible :reason

  validates :reason,
            :allow_blank => true,
            :length => {:minimum => 0, :maximum => 254}

  validates_with UserIdValidator
  validate :validate_blacklisted_user

  def self.list_by_owner(owner)
    # Naprawiam tu babola, podczas usuwania konta, nie jest ono wypisywane z blacklist, lista zbiera
    # konta razem z usuniętymi, próba wyświetlenia usuniętego konta wywala wyjątek
    owner.owned_user_blacklists.includes(:blacklisted).where('users.deleted_at is null').to_a
  end

  # Mówi, czy blacklisted_user jest na czarnej liście użytkownika owner
  def self.on_blacklist?(owner, blacklisted_user)
    raise "Missing owner or member of user blacklist" if !owner || !blacklisted_user

    r = self.where(:user_id => owner.id, :blacklisted_user_id => blacklisted_user.id).limit(1).first
    r.nil? ? false : true
  end

  private

  def validate_blacklisted_user
    if blacklisted.nil?
      errors.add(:blacklisted_user_id, :missing)
      return
    end

    errors.add(:blacklisted_user_id, :is_root)     if blacklisted.has_role? :root
    errors.add(:blacklisted_user_id, :yourself)    if blacklisted.id == owner.id
    errors.add(:blacklisted_user_id, :blacklisted) if UserBlacklist.on_blacklist?(owner, blacklisted)
  end
end
