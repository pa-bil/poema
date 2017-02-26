class Moderation < ActiveRecord::Base
  belongs_to :user
  belongs_to :moderator,      :class_name => 'User', :foreign_key => :moderator_id
  belongs_to :moderateable,   :polymorphic => true

  # @todo: jeśli pozwolimy użytkownikom składać skargi do moderacji, trzeba będzie inaczej obsługiwać dostępność parametrów
  attr_accessible :reason, :complain, :expiry_date

  validates :reason,
            :length => {:minimum => 3, :maximum => 1024},
            :if => lambda { |c| ENV['MIGRATION'].nil? }
  validates :complain,
            :allow_blank => true,
            :length => {:minimum => 3, :maximum => 254}

  before_save :set_user_from_moderateable_owner

  def self.count_uniq(user)
    self.where(:user_id => user.id, :active => true).where("moderateable_type <> ?", User.name).group(:moderateable_type, :moderateable_id).all.count
  end

  def self.list_expired_bans(date)
    self.where(:moderateable_type => User.name, :active => true).where("expiry_date <= ?", date).all
  end

  def self.list_by_user(u)
    self.where(:user_id => u.id).includes(:moderator, :moderateable).order('moderations.id DESC')
  end

  protected

  def set_user_from_moderateable_owner
    if self.moderateable.respond_to?(:owner)
      self.user = self.moderateable.owner
    elsif self.moderateable.instance_of?(User)
      self.user = self.moderateable
    end
  end
end
