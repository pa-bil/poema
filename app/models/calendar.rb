class Calendar < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_object
  acts_as_viewcountable
  acts_as_uploadable
  acts_as_auditable
  acts_as_pretty_url

  belongs_to  :owner,                :class_name => 'User', :foreign_key => :user_id

  has_many    :uploaded_files,       :as => :uploadable,  :dependent => :destroy
  has_many    :comments,             :as => :commentable, :dependent => :destroy
  has_one     :search_index,         :as => :searchable

  attr_accessible :title, :description, :link, :start_date, :start_time, :finish_date, :finish_time, :localisation, :venue, :visible

  validates_with UserIdValidator

  validates :title,
            :length => {:minimum => 3, :maximum => 254}
  validates :description,
            :allow_blank => true,
            :length => {:minimum => 3, :maximum => 1024*100}
  validates :link,
            :allow_blank => true,
            :length => {:minimum => 6, :maximum => 254},
            :format => {:with => URI::regexp(%w(http https))}
  validate  :start_valid?
  validate  :finish_valid?
  validates :localisation,
            :length => {:minimum => 3, :maximum => 512}
  validates :venue,
            :length => {:minimum => 2, :maximum => 254}
  validates :visible,
            :inclusion => { :in => [false,true] }

  before_save :geocode

  # Paginacja, ilość per strona
  self.per_page = 30

  scope :available, where({:banned => false, :visible => true, :deleted_at => nil})

  def start_valid?
    errors.add(:start_date, :empty)   if start_date.to_s.empty?
    errors.add(:start_date, :invalid) if start_date && (Date.parse(start_date.to_s) rescue ArgumentError) == ArgumentError
    errors.add(:start_time, :invalid) if start_time && (Time.parse(start_time.to_s) rescue ArgumentError) == ArgumentError
  end

  def finish_valid?
    unless finish_date.to_s.empty?
      errors.add(:finish_date, :invalid) if (Date.parse(finish_date.to_s) rescue ArgumentError) == ArgumentError
      errors.add(:finish_time, :invalid) if finish_time && (Time.parse(finish_time.to_s) rescue ArgumentError) == ArgumentError
      errors.add(:finish_date, :less_than_start_date) if DateTime.parse("#{finish_date} #{finish_time}") < DateTime.parse("#{start_date} #{start_time}")
    end
  end

  def can_show?
    !destroyed? && !banned? && visible?
  end

  def search_index_content
    [title, description, localisation_geocoder, localisation, venue] if can_show?
  end

  # to jest potrzebne właściwie do obsłużenia migracji, gdzie z uwagi na limity googla, geokodujemy tylko aktualne wydarzenia
  attr_accessor :should_geocode

  geocoded_by :localisation do |c,results|
    Poema::Geocode::update_object(c, results, true) if c.should_geocode
  end

  # Lista dzisiejszych wydarzeń, chcę je wepchnąć do feeda z godziną 00:00
  # Dzięki nadpisaniu wartości pola sortującego feed pojawią się w odpowiednim miejscu
  def self.list_current(limit = 5)
    limit = limit.to_i
    today = Date.current
    available.where('start_date = ? OR finish_date >= ?', today, today).limit(limit).map {|c|
      e = Poema::FeedElement.new(c)
      e.sort_value = today.to_datetime
      e
    }
  end

  # Ostatnio dodane wydarzenia - z tej listy trzeba wywalić wydarzenia przeszłe
  def self.list_recent(limit = 5)
    limit = limit.to_i
    today = Date.current

    w =  ''
    w << 'calendars.id >= (SELECT MAX(id) - ? FROM calendars) '
    w << 'AND (start_date >= ? OR (finish_date IS NOT NULL AND finish_date >= ?))'

    self.available.where(w, (limit*3), today, today).limit(limit).map {|c|
      e = Poema::FeedElement.new(c)
      e.sort_value = c.created_at
      e
    }
  end

  def self.list(start_date, page = nil)
    page = 1 if page.nil?
    self.available.where("start_date >= ? OR (finish_date IS NOT NULL AND finish_date >= ?)", start_date, start_date).includes_owner.page(page.to_i).order("sticky, start_date DESC").to_a
  end
end
