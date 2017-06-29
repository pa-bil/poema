class Publication < ActiveRecord::Base
  include Poema::SortOptions

  scope :available, where(:visible => true, :banned => false, :deleted_at => nil, 'content_copyrights.prohibit_exposition' => false).joins(:content_copyright)

  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_object
  acts_as_viewcountable
  acts_as_uploadable
  acts_as_auditable
  acts_as_pretty_url

  belongs_to  :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to  :container
  belongs_to  :content_copyright

  has_many    :comments,       :as => :commentable, :dependent => :destroy
  has_many    :uploaded_files, :as => :uploadable,  :dependent => :destroy

  has_many    :special_action_publications
  has_many    :special_actions, :through => :special_action_publications

  has_one     :search_index,   :as => :searchable

  attr_accessible :content_copyright_id, :container_id, :title, :intro, :content, :author, :link, :visible, :allow_comments, :translator

  attr_accessor :check_publications_limit

  validates_with ContainerIdValidator
  validates_with UserIdValidator
  validates_with ContentCopyrightValidator
  validates_with PublicationLimitValidator, :if => :check_publications_limit?

  validates :title,
            :length => {:minimum => 1, :maximum => 254}
  validates :intro,
            :allow_blank => true,
            :length => {:maximum => 256}
  validates :content,
            :length => {:minimum => 0, :maximum => 1024*1000}
  validates :author,
            :allow_blank => true,
            :length => {:maximum => 128}
  validates :link,
            :allow_blank => true,
            :length => {:minimum => 6, :maximum => 254},
            :format => {:with => URI::regexp(%w(http https))}
  validates :visible,
            :inclusion => { :in => [false,true] }
  validates :allow_comments,
            :inclusion => { :in => Comment.allow_comments_options.values }
  validates :translator,
            :length => {:maximum => 128},
            :allow_blank => true

  after_save :update_publication_date

  after_create :update_stats_create
  before_update :update_stats_update
  before_destroy :update_stats_destroy

  # Paginacja, ilość per strona
  self.per_page = 50

  # Używam w połączeniu z attr_accessor + kontrolerem + ACL (publication.check_publications_limit = ) do pominięcia dla pewnej grupy osób
  # limitu publikacji, w kontrolerze pomijamy walidację dla :root i :operator
  def check_publications_limit?
    return check_publications_limit.nil? ? true : check_publications_limit
  end

  def can_show?
    allow_from_container = (!container.nil? && container.can_show?) # Publikacja bez kontenera nie pokazuje się, implementuję tutaj tę logikę
    !destroyed? && visible? && !banned? && false == content_copyright.prohibit_exposition? && allow_from_container
  end

  def search_index_content
    [title, intro, content] if can_show?
  end

  def counter_comment
    (counter_comment_neutral + counter_comment_positive + counter_comment_negative)
  end

  def top_level_container
    container.top_level_container
  end

  def self.list(context, sort_id = nil)
    raise "Unsupported context #{context.class.name}" unless context.respond_to? :publications

    begin
      order_by = self.get_sort_field(sort_id, context.sort)
    rescue Poema::Exception::SortUnknownOption
      # context.sort może zawierać nieprawidłowe sortowanie (legacy)
      order_by = self.get_sort_field(sort_id, Poema::SortOptions::SORT_BY_TITLE)
    end

    context.publications.available.joins_view_counter.includes_owner.includes_special_action_existence.order(order_by).to_a
  end

  # Ta metoda przeznaczona jest do listowania publikacji przez samego usera na prywatnej liście
  # pomijam warunki zbanowanych i niewidocznych publikacji
  def self.list_owned(context)
    context.owned_publications.where(:deleted_at => nil).includes(:content_copyright, :container).order("title ASC")
  end

  # Lista publikacji danego użytkownika do prezentacji publicznie innym użytkownikom
  def self.list_by_owner(user, page = nil, sort_id = nil, default_sort_id = SORT_BY_DATE)
    page = 1 if page.nil?
    order_by = self.get_sort_field(sort_id, default_sort_id)

    user.owned_publications.available.joins_view_counter.includes(:container).page(page.to_i).order(order_by).to_a
  end

  # To jest używane eg. w wyszukiwarce, plz note: jeśli którykolwiek z idków z listy nie będzie
  # mógł byc odnaleziony, eg załapie się na warunek where i baza go odrzuci, będzie to RecordNotFound
  def self.list_multi(ids)
    self.available.joins_view_counter.includes_owner.find(ids).to_a
  end

  def self.list_by_published_at(*args)
    since = args.shift
    raise "Missing since argument" if since.nil?

    if args.count > 0                 # jeden argument jest już zdjęty z tablicy
      page = args.shift
      page = 1 if page.nil?           # nil przekazany w argumencie może się pojawić, jeśli podamy do metody params[:page]
                                      # Podmieniam to na pierwszą stronę
    else
      page = nil                      # Jeśli nie podano 2 argumentu (ze stroną) nie używam w ogóle limitów
    end

    result = self.available.joins_view_counter.where("publications.published_at >= :published_at", {:published_at => since}).includes_owner.order("publications.published_at DESC")
    result = result.page(page.to_i) unless page.nil?
    result.to_a
  end

  def self.list_by_conditions(where, bindings, order = "title ASC")
    self.available.where(where, bindings).includes_owner.order(order).to_a
  end

  def self.list_feed(limit = 20)
    limit = limit.to_i
    limit_index = 'publications.id >= (SELECT MAX(id) - ? FROM publications)'

    # Potrzebuję tutaj wynik posortowany po dacie, aby najnowszą publikację wepchnąć jako tę nadrzędna w grupowaniu
    publications = available.where(limit_index, (limit*10)).includes_owner.order('publications.created_at DESC')

    result = {}
    publications.each do |publication|
      index = publication.owner.id.to_s.freeze
      if result.has_key?(index)
        result[index].grouped_elements=publication
      else
        result.store(index, Poema::FeedElement.new(publication))
      end
    end

    result.values.slice(0, limit)
  end

  def included_and_exist_special_action?
    !read_attribute(:special_action_list).nil?
  end

  def list_special_actions(use_db = false)
    if read_attribute(:special_action_list).nil? && use_db
      self.special_actions.where(:deleted_at => nil)
    elsif read_attribute(:special_action_list).nil?
      []
    else
      SpecialAction.find_with_deleted(read_attribute(:special_action_list).split(",").map { |s| s.to_i }).delete_if{|o| o.destroyed?}
    end
  end

  def self.list_all_owned_by(user)
    cc = ContentCopyright.find(Poema::StaticId::get(:content_copyright, :owner))
    self.list_owned(user).keep_if{|p| p.content_copyright.id == cc.id}
  end

  def self.destroy_all_owned_by(user)
    cc = ContentCopyright.find(Poema::StaticId::get(:content_copyright, :owner))
    self.list_owned(user).each do |p|
      p.destroy if p.content_copyright.id == cc.id
    end
  end

  # Metoda mówi, czy status praw autorskich publikacji wskazuje publikację do której prawa autorskie ma
  # osoba publikująca
  def content_copyrights_owned?
    content_copyright.id == Poema::StaticId::get(:content_copyright, :owner) || content_copyright.id == Poema::StaticId::get(:content_copyright, :translation_owner)
  end

  private

  def update_publication_date
    self.update_column(:published_at, self.updated_at) if self.published_at.nil? && self.visible?
  end

  # dokładamy publikację: liczniki ownera podbijamy zawsze, liczniki drzewa
  # podbijamy tylko jeśli publikacja będzie sie w stanie pokazać na liście
  def update_stats_create
    owner_stat = self.owner.stat
    UserStat.increment_counter :counter_publication, owner_stat.id

    if owner_stat.last_publication.nil? || self.created_at > owner_stat.last_publication
      owner_stat.update_column(:last_publication, self.created_at)      # update_column nie aktualizuje timestampów updated_at
    end

    if self.can_show?                                                   # Publikacja ma atrybut widoczności, podbijamy liczniki publikacji
                                                                        # we wszystkich nadrzędnych kontenerach, włączając kontener w którym sie znajduje
      self.container.parents(true).each do |c|
        Container.increment_counter :counter_publication, c.id
        if c.last_publication.nil? || self.created_at > c.last_publication
          c.update_column(:last_publication, self.created_at)
        end
      end
    elsif !(c = self.container).can_show?                               # Tu trochę magii, wiemy, że publikacja nie może sie pokazać, więc nie pobiliśmy jej
                                                                        # liczników. Jeśli publikacja sama z siebie blokuje widoczność, to jest ok, natomiast
                                                                        # jeśli zablokował ją kontener, trzeba i tak podbić liczniki kontenerów blokujących
                                                                        # ponieważ w przypadku odblokowania kontenera, podbija on liczniki publikacji u rodziców
      while !c.nil? && !c.can_show? do
        Container.increment_counter :counter_publication, c.id
        c = c.container
      end
    end
  end

  def update_stats_update
    old = Publication.find(self.id)
    # tu zostaje jeden nieobsłużony przypadek, kiedy publikacja w ukrytym kontenerze zmienia status, w takim
    # przypadku pomimo zmiany statusu samej publikacji, jest ona nadal niewidoczna, wiec nic się nie podbija/zmniejsza
    # trzeba by sprawdzać przyczynę niewidoczności
    if self.can_show? && !old.can_show?
      self.container.parents.each{|c| Container.increment_counter :counter_publication, c.id}
    end
    if !self.can_show? && old.can_show?
      self.container.parents.each{|c| Container.decrement_counter :counter_publication, c.id}
    end
    if self.container_id != old.container_id
     old.container.parents.each{|c| Container.decrement_counter :counter_publication, c.id}
     self.container.parents.each{|c| Container.increment_counter :counter_publication, c.id}
    end
  end

  def update_stats_destroy
    UserStat.decrement_counter :counter_publication, self.owner.stat.id
    if self.can_show?                                                   # Publikacja była widoczna, więc była doliczona do wszystkich
                                                                        # kontenerów w drzewie
      self.container.parents.each do |c|
        Container.decrement_counter :counter_publication, c.id
      end
    elsif !(c = self.container).can_show?                               # Publikacja niewidoczna z powodu wyłączenia widoczności
                                                                        # kontenera jest doliczana do wszystkich niewidocznych kontenerów wyżej
      while !c.nil? && !c.can_show? do
        Container.decrement_counter :counter_publication, c.id
        c = c.container
      end
    end
    true
  end

  def self.sort_fields
    {
      SORT_NATURAL     => 'id',
      SORT_BY_TITLE    => 'title',
      SORT_BY_DATE     => 'published_at DESC',
      3                => 'user_id',
      SORT_BY_VIEWS    => 'view_counter_value_db DESC',
      5                => 'intro',
      SORT_BY_COMMENTS => '(counter_comment_neutral+counter_comment_positive+counter_comment_negative) DESC'
    }
  end
end
