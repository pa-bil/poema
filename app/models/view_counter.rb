class ViewCounter < ActiveRecord::Base
  belongs_to :viewcountable, :polymorphic => true
end
