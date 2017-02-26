class ContentObject < ActiveRecord::Base
  has_many :search_indices
  has_many :comments,       :foreign_key => :commentable_type
  has_many :uploaded_files, :foreign_key => :uploadable_type
end
