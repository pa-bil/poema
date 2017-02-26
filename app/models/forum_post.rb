class ForumPost < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_auditable

  belongs_to :forum_thread
  belongs_to :owner,        :class_name => 'User', :foreign_key => :user_id

  # post jest rodzicem: ma wiele postów pod sobą, jest również dzieckiem
  belongs_to :forum_post
  has_many   :forum_posts,  :dependent => :destroy

  has_one    :search_index, :as => :searchable
  has_many   :moderations,  :as => :moderateable, :dependent => :destroy

  validates_with UserIdValidator

  validates :content,
            :length => {:minimum => 3, :maximum => 1024*20}

  validate :validate_reply_allowance

  attr_accessible :content
  attr_accessor :nesting_level

  after_create :update_stats_create
  after_destroy :update_stats_destroy

  def can_show?
    !destroyed? && forum_thread.can_show?
  end

  def allow_reply?(user)
    return false if deleted? || banned?                                           # na usunięty lub zbanowany nikt nie może odpowiadać
    return false if !user                                                         # jeśli user (zazwyczaj z session_user) jest nil - nie podejmuję dalszej weryfikacji
    return false if UserBlacklist.on_blacklist?(owner, user)                      # jeśli user jest na czarnej liście właściciela postu, nie można odpowiedzieć

    forum_thread.allow_reply?(user)                                               # finałowo pozwalamy odpowiedzieć na posty, które są podpięte do wątku, na który
                                                                                  # można odpowiedzieć
  end

  def search_index_content
    [content] if can_show?
  end

  def update_stats(way)
    p = self
    t = p.forum_thread

    case way
      when Forum::UPDATE_STATS_UP
        return if t.last_activity_at > self.created_at          # to z uwagi na migrację, nie znam kolejności, starsze mogą pojawić się po młodszych

        t.update_column :last_forum_post_id, self.id
        t.update_column :last_activity_at, self.created_at

        t.class.increment_counter :counter_post, t.id
      when Forum::UPDATE_STATS_DOWN
        t.class.decrement_counter :counter_post, t.id
      else
        raise "Unknown way of update stats"
    end

    t.update_stats way
  end

  def anchor
    Digest::MD5.hexdigest("forum_post_#{id}")
  end

  private

  def validate_reply_allowance
    errors.add(:user_id, :deny_policy) unless allow_reply?(owner)
  end

  def update_stats_create
    self.update_stats Forum::UPDATE_STATS_UP
    self.owner.stat.increment_forum_stats self.created_at
  end

  def update_stats_destroy
    self.update_stats Forum::UPDATE_STATS_DOWN
    self.owner.stat.decrement_forum_stats
  end
end
