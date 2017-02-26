class EmailValidator < ActiveModel::Validator
  def validate(record)
    email_regex =  /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    email = record.email.to_s

    if email.length < 6
      record.errors.add(:email, :too_short)
    elsif email.length > 128
      record.errors.add(:email, :too_long)
    elsif email.match(email_regex).nil?
      record.errors.add(:email, :invalid)
    end
  end
end
