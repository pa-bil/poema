class UserValidator < ActiveModel::Validator
  def validate(record)
    raise "Missing .user property" unless record.respond_to?(:user)
    validate_user(record.user, record)
  end

  protected

  def error_key_default
    :user
  end

  def error_key
    options.key?(:error_key) ? options.fetch(:error_key) : error_key_default
  end

  def validate_user(u, record)
    unless u.instance_of?(User)
      record.errors.add(error_key, :missing)
      return
    end

    return if ENV['MIGRATION'] # pomijaj walidację stanu usunięty/zablokowany/zbanowany jeśli idzie proces migracji

    record.errors.add(error_key, :deleted) if (!options.key?(:allow_deleted) || (options.key?(:allow_deleted) && false == options.fetch(:allow_deleted))) && u.deleted?
    record.errors.add(error_key, :locked)  if u.locked?
    record.errors.add(error_key, :banned)  if (!options.key?(:allow_banned) || (options.key?(:allow_banned) && false == options.fetch(:allow_banned))) && u.banned?
  end
end
