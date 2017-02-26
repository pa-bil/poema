class TermsAcceptLog < ActiveRecord::Base
  acts_as_auditable

  belongs_to :terms_version
  belongs_to :user

  attr_accessible :accepted, :terms_version
end
