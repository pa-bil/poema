class ContentCopyrightValidator < ActiveModel::Validator
  def validate(record)
    cc = record.content_copyright
    if cc.nil? || cc.id == Poema::StaticId::get(:content_copyright, :notset)
      record.errors.add(:content_copyright_id, :invalid)
    end
  end
end
