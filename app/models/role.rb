class Role < ActiveRecord::Base
  acts_as_authorization_role

  def self.list_generic
    self.where({:authorizable_type => nil, :authorizable_id => nil}).to_a
  end

  def generic_role?
    self.authorizable_id.nil? && self.authorizable_type.nil?
  end
end
