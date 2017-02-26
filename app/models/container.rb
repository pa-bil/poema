class Container < ActiveRecord::Base
  include Poema::SortOptions

  nilify_blanks
  acts_as_authorization_object
  acts_as_paranoid
  acts_as_viewcountable
  acts_as_uploadable
  acts_as_auditable
  acts_as_pretty_url

  belongs_to  :container
  belongs_to  :owner,          :class_name => 'User', :foreign_key => :user_id

  has_many    :containers,     :dependent => :destroy
  has_many    :publications,   :dependent => :destroy
  has_many    :comments,       :as => :commentable, :dependent => :destroy
  has_many    :uploaded_files, :as => :uploadable,  :dependent => :destroy

  has_one     :search_index,   :as => :searchable

  attr_accessible :title, :intro, :description, :sort, :visible, :allow_comments, :as => :user
  attr_accessible :title, :intro, :description, :sort, :visible, :allow_comments, :granted_container_creator_role_id, :granted_publication_creator_role_id, :force_visibility, :as => :admin

  validates_with ContainerIdValidator
  validates_with UserIdValidator
  validates_with RoleIdValidator

  validates :title,
            :length => {:minimum => 1, :maximum => 254}
  validates :intro,
            :allow_blank => true,
            :length => {:maximum => 254}
  validates :description,
            :allow_blank => true,
            :length => {:maximum => 1024*100}
  validates :visible,
            :inclusion => { :in => [false,true] }
  validates :sort,
            :inclusion => { :in => self.sort_options.values }
  validates :allow_comments,
            :inclusion => { :in => Comment.allow_comments_options.values }

  after_save :order_key_set_if_required

  after_create :update_stats_create
  before_update :update_stats_update
  before_destroy :update_stats_destroy

  def can_show?
    allow_from_container = (container.nil? || container.can_show?)   # Brak nadrzędnego kontenera, lub jesli jest pozwala na pokazwywanie
    !destroyed? && visible? && !banned? && allow_from_container
  end

  def search_index_content
    [title, intro, description] if can_show?
  end

  def parents(include_self = true)
    c = self
    t = include_self ? [c] : []
    until (c = c.container).nil?
      t.push c
    end
    t.reverse
  end

  def top_level_container
    parents.first
  end

  def counter_comment
    (counter_comment_neutral + counter_comment_positive + counter_comment_negative)
  end

  @where_conditions = {:visible => true, :banned => false, :deleted_at => nil}

  def self.list_top_level(full = false, sort_id = nil)
    r = self.where(@where_conditions.merge({:container_id => nil})).order(self.get_sort_field(sort_id, SORT_NATURAL))
    r = r.joins_view_counter.includes_owner if full
    r = r.to_a
  end

  def self.list(context, sort_id = nil, include_empty = false)
    raise "Unsupported context #{context.class.name}" unless context.respond_to? :containers
    begin
      order_by = self.get_sort_field(sort_id, context.sort)
    rescue Poema::Exception::SortUnknownOption
      # W niektórych kontekstach pojawia się niepoprawny identyfikator sortowania domyślnego, ignoruję taki identyfikator
      order_by = self.get_sort_field(sort_id, Poema::SortOptions::SORT_BY_TITLE)
    end
    context.containers.where(@where_conditions).where(include_empty ? 'true' : '(counter_publication > 0 OR force_visibility = 1)').joins_view_counter.includes_owner.order(order_by).to_a
  end

  # elementy ownowane przez context, pomijamy warunki na banowanie i widoczność
  def self.list_owned(context)
    raise "Unsupported context #{context.class.name}" unless context.respond_to? :owned_containers
    context.owned_containers.where(:deleted_at => nil).order('title').to_a
  end

  # To jest używane eg. w wyszukiwarce, plz note: jeśli którykolwiek z idków z listy nie będzie
  # mógł byc odnaleziony, eg załapie się na warunek where i baza go odrzuci, będzie to RecordNotFound
  def self.list_multi(ids)
    self.where(@where_conditions).joins_view_counter.includes_owner.order('title').find(ids).to_a
  end

  def self.find_by_legacy_sec_id(sec_id)
    c = self.joins("JOIN migration_sec_container_map ON migration_sec_container_map.container_id = containers.id").where("migration_sec_container_map.sec_id = ?", sec_id).first
    raise ActiveRecord::RecordNotFound if c.nil?
    c
  end

  def self.destroy_all_empty_owned_by(user)
    self.list_owned(user).each do |c|
      c.destroy if Publication.list(c).count == 0
    end
  end

  private

  def order_key_set_if_required
    if self.order_key.nil?
      self.update_column(:order_key, id)
    end
  end

  def update_stats_create
      UserStat.increment_counter :counter_container, self.owner.stat.id
      if self.can_show?
        self.parents(false).each do |c|
          Container.increment_counter :counter_container, c.id
        end
      elsif !(c = self.container).nil? && !c.can_show?                    # Tutaj dzieje się ta sama magia co kilka linijek niżej, w licznikach
                                                                          # publikacji dla can_show? == false z powodu blokady kontenera nadrzędnego
        while !c.nil? && !c.can_show? do
          Container.increment_counter :counter_container, c.id
          c = c.container
        end
      end

  end

  def update_stats_update
    old = Container.find(self.id)                                         # Biorę dane przed zmianą
    if self.can_show? && !old.can_show?                                   # zmieniamy status z niewidocznego na widoczny:
      self.parents(false).each do |c|
        cn = {:counter_container   => self.counter_container+1,           # trzeba zwiększyć o ilość kontenerów w kontenerze + 1 wszystkie kontenery-rodzice
              :counter_publication => self.counter_publication}           # trzeba zwiększyć o ilość publikacji w kontenerze wszystkie kontenery-rodzice
        Container.update_counters(c.id, cn)
      end
    end
    if !self.can_show? && old.can_show?                                   # zmieniamy status z widocznego na niewidoczny
      self.parents(false).each do |c|
        cn = {:counter_container   => (self.counter_container+1)*-1,      # pomniejszamy pulę kontenerów, u rodziców, o tyle, ile mam samemu + ja
              :counter_publication => (self.counter_publication)*-1}      # pomniejszamy pulę publikacji
        Container.update_counters(c.id, cn)
      end
    end
    if self.container_id != old.container_id                              # kontener zmienia położenie
      old.parents(false).each do |c|
        cn = {:counter_container   => (self.counter_container+1)*-1,      # odejmujemy ze starego pulę własnych kontenerów
              :counter_publication => (self.counter_publication)*-1}      # pomniejszamy pulę publikacji
        Container.update_counters(c.id, cn)
      end
      self.parents(false).each do |c|
        cn = {:counter_container   => self.counter_container+1,           # dodajemy do nowego pulę własnych kontenerów
              :counter_publication => self.counter_publication}           # zwiększamy pulę publikacji
        Container.update_counters(c.id, cn)
      end
    end
  end

  def update_stats_destroy
                                                                          # W kontenerze obsługujemy dekrementacji publikacji ponieważ
                                                                          # ma on podłączony :dependent => :destroy, co wywoła before_destroy(record)
                                                                          # na każdej z publikacji pozwalając sie jej odliczyć
    UserStat.decrement_counter :counter_container, self.owner.stat.id
    if self.can_show?                                                     # Kontener widoczny był doliczony do drzewa rodziców
      self.parents(false).each do |c|
        Container.decrement_counter :counter_container, c.id
      end
    elsif !(c = self.container).nil? && !c.can_show?                      # Kontener niewidoczny był doliczony wraz ze swoimi
                                                                          # publikacjami do drzewa niewidocznych kontenerów wyżej
      while !c.nil? && !c.can_show? do
        Container.decrement_counter :counter_container, c.id
        c = c.container
      end
    end
  end

  def self.sort_fields
    {
      SORT_NATURAL     => 'order_key',
      SORT_BY_TITLE    => 'title',
      SORT_BY_DATE     => 'created_at DESC',
      3                => 'user_id',
      SORT_BY_VIEWS    => 'view_counter_value_db DESC',
      5                => 'intro',
      SORT_BY_COMMENTS => '(counter_comment_neutral+counter_comment_positive+counter_comment_negative) DESC'
    }
  end
end

