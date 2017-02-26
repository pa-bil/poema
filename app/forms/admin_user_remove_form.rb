class AdminUserRemoveForm  < ActiveForm
  attr_accessor :user, :remove_pubs_owned, :remove_personal_data, :reason

  validates :remove_pubs_owned,
            :inclusion => { :in => ['0','1'] }
  validates :remove_personal_data,
            :inclusion => { :in => ['0','1'] }
  validates :reason,
            :length => {:minimum => 5, :maximum => 1024}

  validates_with UserValidator, :allow_banned => true, :allow_deleted => true

  # Trzeba pamiętać, że ActiveForm wszystkie dane trzyma jako string, w szczególności checkboxy, są w postaci '0' co
  # jest logicznym true

  def remove_pubs_owned?
    1 == remove_pubs_owned.to_i
  end

  def remove_personal_data?
    1 == remove_personal_data.to_i
  end
end