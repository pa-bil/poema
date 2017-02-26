class ForumThread < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_object
  acts_as_viewcountable
  acts_as_auditable
  acts_as_pretty_url

  scope :available, where(:banned => 0, :deleted_at => nil)

  belongs_to :forum
  belongs_to :owner,           :class_name => 'User', :foreign_key => :user_id

  has_many   :forum_posts,     :dependent => :destroy
  has_many   :moderations,     :as => :moderateable,  :dependent => :destroy

  has_one    :last_forum_post, :class_name => 'ForumPost', :foreign_key => :id, :primary_key => :last_forum_post_id
  has_one    :search_index,    :as => :searchable

  belongs_to :closed_by,      :class_name => 'User', :foreign_key => :closed_by_user_id

  validates_with UserIdValidator

  validates :title,
            :presence => true,
            :length => {:maximum => 254}
  validates :content,
            :presence => true,
            :length => {:maximum => 1024*20}
  validates :closed,
            :inclusion => { :in => [false,true] }

  attr_accessible :title, :content, :closed, :as => :creator  # user tworzący wątek może ustawiać tytuł i treść
  attr_accessible :closed, :as => :updater                    # user aktualizujący wątek może go tylko zamknąć

  before_validation :set_last_activity
  after_create :update_stats_create
  after_destroy :update_stats_destroy

  # Paginacja, ilość wątków per strona
  self.per_page = 10

  def set_last_activity
    write_attribute(:last_activity_at, Time.zone.now)
  end

  def can_show?
    !destroyed? && !banned? && forum.can_show?
  end

  # Metoda mówi, czy użytkownik user może dodać odpowiedź (forum_post) do tego wątku
  def allow_reply?(user)
    return false if deleted? || banned?                                           # na usunięty lub zbanowany nikt nie może odpowiadać
    return false if !user                                                         # jeśli user (zazwyczaj z session_user) jest nil - nie podejmuję dalszej weryfikacji
    return false if UserBlacklist.on_blacklist?(owner, user)                      # jeśli user jest na czarnej liście właściciela wątku, nie można odpowiedzieć
    !closed? || (closed? && closed_by == user)                                    # końcowe sprawdzenie, wątek nie może być zamknięty, lub odpowiadający musi być
                                                                                  # właścicielem zamkniętego wątku
  end

  def search_index_content
    [title, content] if can_show?
  end

  # lista ostatnio aktywnych wątków na stronę główną
  def self.list_recent(limit = 10)
    limit = limit.to_i
    limit_index = 'forum_threads.id >= (SELECT MAX(id) - ? FROM forum_threads)'

    available.where(limit_index, (limit*3)).includes_owner.includes(:forum, :forum_posts => [includes_owner_param]).order("last_activity_at DESC").limit(limit).map{|thread|
      grouping = Poema::FeedElement.new(thread)
      grouping.sort_value = thread.last_activity_at
      thread.forum_posts.each do |post|
        grouping.grouped_elements=post.owner
      end
      grouping
    }
  end

  # Ta metoda zwraca listę odpowiedzi dla danego postu w formie drzewa
  def list_posts
    result = []
    posts = forum_posts.where(:deleted_at => nil).includes_owner.order(:id).to_a
                                                                                  # lista odpowiedzi posortowana po idkach, zachowana jest chronologia odpowiedzi
                                                                                  # Pytam także o posty zbanowane aby zachować kolejność
    while posts.count > 0 do
      p = posts.shift                                                             # przekładamy posty z listy to tablicy z wynikiem
      if p.forum_post_id.nil?                                                     # wszystkie bezpośrednio dowiązane do wątku dokładamy na koniec
        p.nesting_level = 0
        result.push(p)
      else                                                                        # odpowiedź jest dowiązana do innej odpowiedzi
        Array.new(result).each_index do |i|                                       # iteracja po kopii wyniku: szukamy w nim postu do którego dowiązana jest odpowiedź p
          if result[i].id == p.forum_post_id
            p.nesting_level = (result[i].nesting_level + 1)
            c = (i + 1)
            while result[c] && result[c].nesting_level >= p.nesting_level do      # znaleziono, przy czym na następnej pozycji mogą się znaleźć wcześniejsze odpowiedzi
                                                                                  # lub odpowiedzi zagnieżdżone głębiej, szukamy pierwszej z levelem niższym niż własny
              c = (c + 1)
            end
            result.insert(c, p)
          end
        end
      end
    end
    result
  end

  def update_stats(way)
    t = self
    f = t.forum

    case way
      when Forum::UPDATE_STATS_UP
        return if f.last_activity_at > t.last_activity_at            # to z uwagi na migrację, nie znam kolejności, starsze mogą pojawić się po młodszych

        f.update_column :last_forum_thread_id, t.id
        f.update_column :last_activity_at, t.last_activity_at        # jeśli wątek jest nowy, użyj daty utworzenia

        f.class.increment_counter :counter_post, f.id
      when Forum::UPDATE_STATS_DOWN
        f.class.decrement_counter :counter_post, f.id
      else
        raise "Unknown way of update stats"
    end
  end

  private

  def update_stats_create
    self.update_stats Forum::UPDATE_STATS_UP
    self.owner.stat.increment_forum_stats self.created_at
  end

  def update_stats_destroy
    self.update_stats Forum::UPDATE_STATS_DOWN
    self.owner.stat.decrement_forum_stats
  end
end
