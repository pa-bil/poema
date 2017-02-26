class AuthCorrectPasswordValidator  < ActiveModel::Validator
  def validate(record)
    raise "Missing .auth property" unless record.respond_to?(:auth)
    raise "Missing .password property" unless record.respond_to?(:password)

    a = record.auth
    pass = record.password

    unless a.instance_of?(Auth)
      record.errors.add(:password, :missing)
      return
    end

    if pass.to_s.length == 0
      record.errors.add(:password, :blank)
      return
    end

    if a.deleted?
      record.errors.add(:password, :deleted)
    elsif !a.password_check(pass)
      record.errors.add(:password, :invalid)
    end
  end
end
