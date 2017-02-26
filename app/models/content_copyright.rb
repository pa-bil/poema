class ContentCopyright < ActiveRecord::Base
  has_many :publications
  has_many :uploaded_files
end
