class UploadedFileUserQuotaValidator < ActiveModel::Validator
  def validate(record)
    owner = record.owner
    if owner.nil?
      record.errors.add(:file, :owner_missing)
    else
      # olej walidację quoty podczas migracji, niektórzy użytkownicy mają niespójności
      return if ENV['MIGRATION']

      quota = owner.quota
      # quota == nil oznacza brak limitów, nie waliduję niczego, zero oznacza
      # brak przydziału na pliki
      unless quota.nil?
        sum = UploadedFile.get_sum_of_uploaded_files(owner)

        # @todo jak dobrać sie do rozmiaru przesyłanego pliku? record.file_file_size jest null, choć debug pokazuje wartość
        if sum.bytes + 1 > quota.megabytes
          record.errors.add(:file, :quota_limit_reached)
        end
      end
    end
  end
end
