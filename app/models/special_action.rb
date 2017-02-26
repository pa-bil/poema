class SpecialAction < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_object
  acts_as_pretty_url

  has_many :special_action_publications
  has_many :publications, :through => :special_action_publications

  attr_accessible :title, :description, :promoter_title, :promoter_description, :icon_url, :visible, :start_date, :start_time, :finish_date, :finish_time, :send_notification

  validates_with RoleIdValidator

  validates :title,
            :length => {:minimum => 1, :maximum => 254}
  validates :description,
            :allow_blank => true,
            :length => {:minimum => 1, :maximum => 1024*10}
  validates :promoter_title,
            :length => {:minimum => 1, :maximum => 254}
  validates :promoter_description,
            :allow_blank => true,
            :length => {:minimum => 1, :maximum => 1024*3}
  validates :icon_url,
            :length => {:maximum => 254},
            :format => {:with => /^\/assets\/(.*)\.(gif|jpg|jpeg|png)$/ }
  validates :visible,
            :inclusion => { :in => [false,true] }
  validates :send_notification,
            :inclusion => { :in => [false,true] }

  validate  :start_valid?
  validate  :finish_valid?

  scope :not_deleted, where({:deleted_at => nil})
  scope :available, where({:visible => true, :deleted_at => nil})

  def can_show?
    now = Date.current
    !destroyed? && visible? && (start_date.nil? || start_date <= now) && (finish_date.nil? || finish_date >= now)
  end

  def self.list_admin(page)
    page = 1 if page.nil?
    self.not_deleted.page(page.to_i).order('visible DESC, created_at DESC').to_a
  end

  def self.list_active
    where = ''
    where << "(start_date IS NULL) OR (CAST(CONCAT(IFNULL(start_date, CURRENT_DATE()),' ', IFNULL(start_time, '00:00:00')) AS DATETIME) <= ?) "
    where << 'AND '
    where << "(finish_date IS NULL) OR (CAST(CONCAT(IFNULL(finish_date, CURRENT_DATE()),' ', IFNULL(finish_time, '23:59:59')) AS DATETIME) >= ?) "
    self.available.where(where, DateTime.current, DateTime.current).to_a
  end

  def self.list
    where = "(start_date IS NULL) OR (CAST(CONCAT(IFNULL(start_date, CURRENT_DATE()),' ', IFNULL(start_time, '00:00:00')) AS DATETIME) <= ?)"
    self.available.where(where, DateTime.current).order(:title).to_a
  end

  def list_publications(page, sort_id, default_sort_id)
    page = 1 if page.nil?
    order_by = Publication.get_sort_field(sort_id, default_sort_id)

    publications.available.joins_view_counter(Publication).includes_owner.order(order_by).page(page.to_i).to_a
  end

  def start_valid?
    unless start_date.to_s.empty?
      errors.add(:start_date, :invalid) if start_date && (Date.parse(start_date.to_s) rescue ArgumentError) == ArgumentError
      errors.add(:start_time, :invalid) if start_time && (Time.parse(start_time.to_s) rescue ArgumentError) == ArgumentError
    end
  end

  def finish_valid?
    unless finish_date.to_s.empty?
      errors.add(:finish_date, :invalid) if (Date.parse(finish_date.to_s) rescue ArgumentError) == ArgumentError
      errors.add(:finish_time, :invalid) if finish_time && (Time.parse(finish_time.to_s) rescue ArgumentError) == ArgumentError
      errors.add(:finish_date, :less_than_start_date) if DateTime.parse("#{finish_date} #{finish_time}") < DateTime.parse("#{start_date} #{start_time}")
    end
  end
end
