Struct.new('CommentStat', :commentable, :percent, :count)

class Comment < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_auditable :anonymous => true

  belongs_to :owner,          :class_name => 'User', :foreign_key => :user_id
  belongs_to :content_object, :foreign_key => :commentable_type
  belongs_to :commentable,    :polymorphic => true

  has_many   :moderations,    :as => :moderateable, :dependent => :destroy

  # Te walidatory tyko dla anonimowych komentarzy
  validates_with EmailValidator, :if => lambda { |c| c.owner.nil? }
  validates_with CurrentTermsValidator, :if => lambda { |c| ENV['MIGRATION'].nil? && c.owner.nil? }
  validates :name,
            :length => {:minimum => 2, :maximum => 256},
            :if => lambda { |c| c.owner.nil? }

  # Pozostałe zawsze
  validates :content,
            :length => {:minimum => 2, :maximum => 1024*3}
  validates :emotion,
            :inclusion => {:in => [-1, 0, 1]}

  validate :validate_policy_for_commentable

  attr_accessor :terms_version_id

  attr_accessible :content, :emotion, :name, :email, :terms_version_id, :as => :anonymous
  attr_accessible :content, :emotion, :as => :user

  after_create :update_stats

  # Paginacja, ilość komentarzy per strona
  self.per_page = 10

  def self.allow_comments_options
    m = {}
    o = {"activerecord.allow_comments.default"    => ALLOW_DEFAULT,
         "activerecord.allow_comments.registered" => ALLOW_REGISTERED,
         "activerecord.allow_comments.nobody"     => ALLOW_NOBODY}
    o.each_pair do |k,v|
      m[I18n.t k] = v
    end
    m
  end

  ALLOW_ALL = 'A'
  ALLOW_REGISTERED = 'R'
  ALLOW_NOBODY = 'N'
  ALLOW_DEFAULT = 'D'

  DEFAULT = ALLOW_REGISTERED

  POLICY_DENY = 1
  POLICY_REQUIRE_AUTH = 2
  POLICY_ALLOW = 3

  def self.check_policy_for_commentable(commentable, user)
    # Zawsze pozwalamy komentować użytkownikowi, który jest rootem
    return POLICY_ALLOW if user && user.has_role?(:root)

    # By default nie pozwalamy na komentowanie czegokolwiek, co dostało bana
    # lub owner obiektu commentable dodał użytkownika user do czarnej listy
    if (commentable.respond_to?(:banned?) && commentable.banned?) || (user && UserBlacklist.on_blacklist?(commentable.owner, user))
      return POLICY_DENY
    end

    policy = (false == commentable.respond_to?(:allow_comments) || commentable.allow_comments == ALLOW_DEFAULT) ? DEFAULT : commentable.allow_comments
    case policy
      when ALLOW_NOBODY
        POLICY_DENY
      when ALLOW_REGISTERED
        user.nil? ? POLICY_REQUIRE_AUTH : POLICY_ALLOW
      when ALLOW_ALL
        # @fixme 2 kwietnia 2014, wyłączam mozliwość ustawienia komentowania niezalogowanym z uwagi na spam przy czym nie chcę aktualizować w bazie
        # istniejacych pozwoleń - jest ich sporo i nie wiem czy sie nie wycofam z tego kiedyś - tak wiec zmieniam logikę apikacji, tak, aby wymagała
        # logowania dla obiektów pozwalajacych na komentowanie niezalogowanym
        # POLICY_ALLOW
        user.nil? ? POLICY_REQUIRE_AUTH : POLICY_ALLOW
      else
        raise "Unknown comment policy"
    end
  end

  def self.allowed_by_commentable?(commentable, user)
    POLICY_ALLOW == self.check_policy_for_commentable(commentable, user)
  end

  def self.calculate_stats(context)
    pts = 0.to_f
    cnt = 0
    context.comments.where(:deleted_at => nil, :banned => false).each do |c|
      pts = pts + (c.emotion == 0 ? 0.5 : c.emotion.to_f)
      cnt = cnt + 1
    end
    percent = cnt > 0 ? ((pts.to_f/cnt.to_f) * 100).round : 0
    Struct::CommentStat.new(context, percent, cnt)
  end

  def self.list(context, page = nil)
    raise "Unsupported context #{context.class.name}" unless context.respond_to? :comments
    page = 1 if page.nil?
    self.assign_anonymous_users(context.comments.where(:deleted_at => nil).includes_owner.page(page.to_i).order("created_at DESC").to_a)
  end


  def self.list_owned(by, limit = 10)
    by.owned_comments.where(:deleted_at => nil, :banned => false).includes(:commentable => [includes_owner_param]).limit(limit.to_i).order("created_at DESC").to_a
  end

  def self.list_feed(limit = 15)
    limit = limit.to_i
    limit_index = 'comments.id >= (SELECT MAX(id) - ? FROM comments)'

    # Potrzebuję tutaj wynik posortowany po dacie, aby najnowszy komentarz wepchnąć jako tęn nadrzędny w grupowaniu
    comments = where(:deleted_at => nil, :banned => false).where(limit_index, (limit*10)).includes_owner.includes(:commentable => [includes_owner_param]).order('comments.created_at desc')
    comments = assign_anonymous_users(comments)

    result = {}

    comments.each do |comment|
      index = comment.commentable_type + comment.commentable_id.to_s.freeze
      if result.has_key?(index)
        result[index].grouped_elements=comment.owner
      else
        result.store(index, Poema::FeedElement.new(comment))
      end
    end

    result.values.slice(0, limit)
  end

  def anchor
    Digest::MD5.hexdigest("comment_#{id}")
  end

  private

  # Ten walidator dokonuje ostatecznego sprawdzenia, czy komentarz jest zgodny z polityką, kontroler
  # powyżej powinien wyrzucić 404, w przypadku braku dostępu, nie mniej jednak coś się może zmienić
  # w czasie pomiędzy otworzeniem strony z formularzem, a submitem
  def validate_policy_for_commentable
    errors.add(:commentable_id, :deny_policy) unless Comment.allowed_by_commentable?(commentable, owner)
  end

  def self.assign_anonymous_users(comments = [])
    # Na listę komentów trzeba nałożyć puste obiekty userów anonimowych, będą potrzebne aby zachować jednakową
    # konwencję (owner)
    comments.collect!{|c|
      if c.user_id.nil?
        c.owner = User.new(:name => c.name, :email => c.email)
        c.owner.readonly!
      end
      c
    }
  end

  def update_stats
    case self.emotion
      when -1
        commentable_counter = :counter_comment_negative
        owner_counter = :counter_commented_negative
      when  0
        commentable_counter = :counter_comment_neutral
        owner_counter = :counter_commented_neutral
      when  1
        commentable_counter = :counter_comment_positive
        owner_counter = :counter_commented_positive
      else
        raise "Unknown comment emotion"
    end

    owner_stat = nil
    owner_stat = self.owner.stat unless self.owner.nil?

    self.commentable.class.increment_counter commentable_counter, self.commentable.id
    UserStat.increment_counter(owner_counter, owner_stat.id) if owner_stat

    # data otrzymania ostatniego komentarza w obiekcie
    # ify porównujące daty są potrzebne z uwagi na migrację, nie znam kolejności w której będą
    # dokładane komentarze, później załadowany starszy nie powinien zmienić na starszą daty ostatniego komentarza
    if self.commentable.last_comment.nil? || self.created_at > self.commentable.last_comment
      self.commentable.update_column(:last_comment, self.created_at)
    end

    # statystyki osoby komentującej
    if owner_stat && (owner_stat.last_commented.nil? || self.created_at > owner_stat.last_commented)
      owner_stat.update_column(:last_commented, self.created_at)
    end
  end
end
