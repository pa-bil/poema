class UserSelfRemoveForm < ActiveForm
  attr_accessor :user, :auth, :confirmation, :remove_pubs_owned, :confirmation_pubs, :confirmation_opinions, :password

  validates :confirmation,
            :acceptance => true
  validates :confirmation_pubs,
            :acceptance => true
  validates :confirmation_opinions,
            :acceptance => true
  validates :remove_pubs_owned,
            :inclusion => { :in => ['0','1'] }

  validates_with UserValidator, :allow_banned => true
  validates_with AuthCorrectPasswordValidator

  def remove_pubs_owned?
    1 == remove_pubs_owned.to_i
  end
end
