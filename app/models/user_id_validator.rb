class UserIdValidator < UserValidator
  def validate(record)
    # find_by_id ponieważ a) zwróci nil jeśli rekordu nie ma, nie wywali wyjątku jeśli rekord będzie usunięty
    validate_user(User.find_by_id(record.user_id), record)
  end

  protected

  def error_key_default
    :user_id
  end
end
