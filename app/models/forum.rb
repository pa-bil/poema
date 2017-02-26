class Forum < ActiveRecord::Base
  UPDATE_STATS_UP = 1
  UPDATE_STATS_DOWN = 2

  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_object
  acts_as_pretty_url

  has_many :forum_threads,       :dependent => :destroy

  has_one  :last_forum_thread,   :class_name  => 'ForumThread', :primary_key => :last_forum_thread_id, :foreign_key => :id
  has_one  :search_index,        :as => :searchable

  @owner = nil

  validates :title,
    :length => {:minimum => 1, :maximum => 254}
  validates :description,
    :allow_blank => true,
    :length => {:maximum => 1024*5}

  validates :visible,
    :inclusion => { :in => [false,true] }
  validates :moderated,
    :inclusion => { :in => [false,true] }
  validates :allow_html,
    :inclusion => { :in => [false,true] }

  attr_accessible :title, :description, :visible, :moderated, :allow_html

  attr_accessor :owner

  def authorization_roles
    if  @owner.nil?
      raise "Please set forum owner"
    end
    {:owner => @owner}
  end

  def can_show?
    !destroyed? && visible? && !banned?
  end

  def search_index_content
    [title, description] if can_show?
  end

  # Lista forów
  def self.list
    self.where({:banned => false, :visible => true, :deleted_at => nil}).includes(:last_forum_thread => [includes_owner_param]).order(:title).to_a
  end

  def list_threads(page = nil)
    page = 1 if page.nil?
    self.forum_threads.joins_view_counter.where({:banned => false, :deleted_at => nil}).includes_owner.includes(:last_forum_post => [self.class.includes_owner_param]).page(page.to_i).order("sticky, last_activity_at DESC").to_a
  end
end
