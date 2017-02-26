class SearchIndex < ActiveRecord::Base
  belongs_to :content_object, :foreign_key => :searchable_type
  belongs_to :searchable,     :polymorphic => true
end
