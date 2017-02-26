class CurrentTermsValidator < ActiveModel::Validator
  def validate(record)
    return if ENV['MIGRATION'] # pomijaj walidację stanu usunięty/zablokowany/zbanowany jeśli idzie proces migracji
        
    ct = TermsVersion.current!
    if record.terms_version_id.to_i != ct.id
      record.errors.add(:terms_version_id, :not_current)
    end
  end
end
