class User < ActiveRecord::Base
  scope :available, where({:locked => 0, :banned => 0, :visible => 1, :deleted_at => nil})

  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_subject
  acts_as_authorization_object
  acts_as_viewcountable
  acts_as_partial_validation
  acts_as_uploadable
  acts_as_auditable
  acts_as_pretty_url

  has_and_belongs_to_many :roles

  belongs_to  :auth

  # To jest workaround na includes używany w relacjach polimorficznych podłączonych do User
  # eg. komentarze, gdzie by default dołączamy komentowany obiekt i ładujemy mu relacje ownera
  belongs_to  :owner,                   :class_name => 'User', :foreign_key => :id

  belongs_to  :terms_version

  has_many    :terms_accept_logs

  has_many    :user_update_logs
  has_many    :password_reminders

  has_one     :stat,                    :class_name => 'UserStat'
  has_one     :rank,                    :class_name => 'UserRank', :foreign_key => :id

  has_one     :user_signup_activation

  # Te relacje mówią, że User jest właścicielem czegoś, dodał coś (plik, kontener, komentarz)
  has_many    :owned_uploaded_files,    :class_name => 'UploadedFile'
  has_many    :owned_containers,        :class_name => 'Container'
  has_many    :owned_publications,      :class_name => 'Publication'
  has_many    :owned_comments,          :class_name => 'Comment'
  has_many    :owned_forum_threads,     :class_name => 'ForumThread'
  has_many    :owned_forum_posts,       :class_name => 'ForumPost'
  has_many    :owned_calendars,         :class_name => 'Calendar'
  has_many    :owned_user_blacklists,   :class_name => 'UserBlacklist'

  # Te relacje opisują czarne listy użytkowników
  # :blacklisted_users - użytkownicy, których blacklistuję, :blacklisted_by - użytkownicy, którzy blacklistują mnie
  has_many    :blacklisted_users,       :class_name => 'User', :through => :owned_user_blacklists, :source => :blacklisted
  has_many    :blacklisted_by,          :class_name => 'User', :through => :owned_user_blacklists, :source => :owner

  # Te relacje mówią, ze do User'a są przypięte pewne elementy, eg pliki w galerii, komentarze
  has_one     :search_index,            :as => :searchable

  has_many    :user_blacklists_member,  :class_name => 'UserBlacklist', :foreign_key => :blacklisted_user_id
  has_many    :uploaded_files,          :as => :uploadable,   :dependent => :destroy
  has_many    :comments,                :as => :commentable,  :dependent => :destroy
  has_many    :moderations,             :as => :moderateable

  # potrzebne via commentable (używamy zazwyczaj tiutle jako opisu komentowanego elementu)
  alias_attribute :title, :name

  attr_accessible :name, :gender, :intro, :description, :email, :im_gadugadu, :im_tlen, :website, :localisation,
                  :longitude, :latitude, :visible, :sendmails, :terms_version_id, :allow_comments

  validates :name,
            :length => {:minimum => 1, :maximum => 128},
            :if => lambda { |obj| obj.section? "personal"}
  validates :gender,
            :inclusion => { :in => %w(M F) },
            :if => lambda { |obj| obj.section? "personal"}

  validates :intro,
            :allow_blank => true,
            :length => {:minimum => 0, :maximum => 1024*5},
            :if => lambda { |obj| obj.section? "personal"}
  validates :description,
            :allow_blank => true,
            :length => {:minimum => 0, :maximum => 1024*5},
            :if => lambda { |obj| obj.section? "personal"}
  validate  :no_urls_in_personal_data,
            :if => lambda { |obj| obj.section? "personal"}

  validates :email,
            :length => {:minimum => 6, :maximum => 128},
            :format => {:with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i},
            :uniqueness => {:case_sensitive => false},
            :if => lambda { |obj| obj.section? "contact" }
  validates :im_gadugadu,
            :allow_blank => true,
            :numericality => { :only_integer => true },
            :if => lambda { |obj| obj.section? "contact" }
  validates :im_tlen,
            :allow_blank => true,
            :length => {:minimum => 3, :maximum => 100},
            :if => lambda { |obj| obj.section? "contact" }
  validates :website,
            :allow_blank => true,
            :length => {:minimum => 6, :maximum => 254},
            :format => {:with => URI::regexp(%w(http https))},
            :if => lambda { |obj| obj.section? "contact" }
  validates :localisation,
            :allow_blank => true,
            :length => {:minimum => 6, :maximum => 254},
            :if => lambda { |obj| obj.section? "localisation" }

  validates_with CurrentTermsValidator,
            :if => lambda { |obj| obj.section? "confirmation" }

  before_update  :update_log
  before_destroy :anonymize_personal_data
  before_save    :geocode
  after_create   :create_related_records

  def no_urls_in_personal_data
    regexp_1 = /(^|["'(\s]|&lt;)(www\..+?\..+?)((?:[:?]|\.+)?(?:\s|$)|&gt;|[)"',])/
    regexp_2 = /(^|["'(\s]|&lt;)((?:(?:https?|ftp):\/\/|mailto:).+?)((?:[:?]|\.+)?(?:\s|$)|&gt;|[)"',])/

    errors.add(:name, :url_found) if name =~ regexp_1 ||  name =~ regexp_2

    # userom z rankingiem wykazującym jakąkolwiek aktywność pozwalamy na posiadanie linków w opisach
    return if !rank.nil? && rank.rank_trusted?

    errors.add(:intro, :url_found) if intro =~ regexp_1 || intro =~ regexp_2
    errors.add(:description, :url_found) if description =~ regexp_1 || description =~ regexp_2
  end

  # Paginacja, ilość per strona
  self.per_page = 50

  # Jeśli obiekt jest nakładany na listę aby podstawić nazwę, etc z innego źródła (eg komentarze) traktuj użytkownika jako anonimowego
  def anonymous?
    new_record? || id.nil?
  end

  def can_show?
    !destroyed? && !locked? && !banned?
  end

  def authorization_roles
    {:owner => self}
  end

  def assign_default_roles
    self.has_role! :user
  end

  def search_index_content
    [name, intro, description] if can_show?
  end

  def pretty_url_slug
    name
  end

  # Ta metoda nadpisuje zachowanie sprawdzania autoryzacji dla użytkownika:
  # - dla obiektów (obj), które mają propercje granted_* w postaci identyfikatorów generycznych ról (int :operator, :user),
  #   zamienia je na nazwy, dotyczy eg. Container
  # - tworzy pseudo-rolę :banned, którą posiada użytkownik z banem
  def has_role?(role_name, obj = nil)
    if !obj.nil? && !(role_name.to_s =~ /granted_/).nil?
      f = role_name.to_s + '_role_id'
      if obj.attributes.has_key?(f) && !obj.attributes[f].nil?
        r = Role.find(obj.attributes[f])
        return super r.name
      end
    elsif role_name.to_sym == :banned
      return banned?
    end
    super
  end

  def has_any_of_roles?(*args)
    return false if args.count == 0

    if args.first.instance_of?(Array)
      roles = args.first
    else
      roles = args
    end

    roles.each do |role|
      return true if has_role? role
    end
    false
  end

  geocoded_by :localisation do |u,results|
    Poema::Geocode::update_object(u, results)
  end

  def ban_count
    self.moderations.all.count
  end

  def self.list_recent(limit = 5)
    limit = limit.to_i
    limit_index = 'users.id >= (SELECT MAX(id) - ? FROM users)'

    available.where(limit_index, (limit*3)).includes_owner.limit(limit).map{|user| Poema::FeedElement.new(user) }
  end

  # To jest używane eg. w wyszukiwarce, plz note: jeśli którykolwiek z idków z listy nie będzie
  # mógł byc odnaleziony, eg załapie się na warunek where i baza go odrzuci, będzie to RecordNotFound
  def self.list_multi(ids)
    self.available.order('name').find(ids).to_a
  end

  def self.search_admin(q, page = nil)
    page = 1 if page.nil?

    q_like = self.sanitize("%#{q}%")
    q_exact = self.sanitize(q)

    j = "LEFT JOIN user_update_logs ON user_update_logs.user_id = users.id"
    w = "users.id = #{q_exact} OR users.name LIKE #{q_like} OR users.email LIKE #{q_like} OR auths.login LIKE #{q_like} OR user_update_logs.value LIKE #{q_like}"

    self.joins(:auth).joins(:rank).joins(j).where(w).group('users.id').page(page.to_i).order('users.id').to_a
  end

  protected

  def update_log
    u = User.find_with_deleted(id)
    u.user_update_logs << UserUpdateLog.new(:field_name => 'name',  :value => u.name)  if u.name  != name
    u.user_update_logs << UserUpdateLog.new(:field_name => 'email', :value => u.email) if u.email != email
  end

  def anonymize_personal_data
    # Operuję bezpośrednio na atrybutach ponieważ chcę pominąc walidację. Niektórzy użytkownicy w momencie usunięcia mogą mieć eg. niezaakceptowaną nową wersję regulaminu
    self.attributes = {
      :name        => I18n.t('activerecord.misc.user_removed'),
      :email       => "anonymous+removed.#{id}@some.domain.com",
      :im_gadugadu => nil,
      :im_tlen     => nil,
      :website     => nil,
      :visible     => false
    }
    raise Exception "Failed to anonymize user's personal data" unless self.save(:validate => false)
  end

  def create_related_records
    self.create_stat
    self.build_rank.save!
  end
end
