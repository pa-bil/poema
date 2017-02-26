class Audit < ActiveRecord::Base
  nilify_blanks

  belongs_to :auditable, :polymorphic => true
  belongs_to :user

  attr_accessible :event_type, :level, :ip, :description, :user
  attr_accessor :anonymous

  LEVEL_INFO              = 1
  LEVEL_NOTICE            = 2
  LEVEL_ERROR             = 3

  EVENT_ERROR             = 0
  EVENT_CREATE            = 1
  EVENT_UPDATE            = 2
  EVENT_DESTROY           = 3
  EVENT_MOVE              = 4
  EVENT_AUTH              = 5
  EVENT_APPLICATION_ERROR = 6
  EVENT_OTHER             = 7

  validates :event_type,
            :inclusion => {:in => [EVENT_ERROR, EVENT_CREATE, EVENT_UPDATE, EVENT_DESTROY, EVENT_MOVE, EVENT_AUTH, EVENT_APPLICATION_ERROR, EVENT_OTHER]}
  validates :level,
            :inclusion => {:in => [LEVEL_INFO, LEVEL_NOTICE, LEVEL_ERROR]}
  validates :user_id,
            :numericality => { :only_integer => true },
            :unless => lambda { |obj| obj.anonymous? }
  validates :ip,
            :ip_addr => true,
            :if => lambda { |obj| obj.respond_to?(:is_http_request) }
  validates :description,
            :allow_blank => true,
            :length => {:maximum => 1024}

  # Paginacja, ilość rekordów per strona
  self.per_page = 50

  def anonymous?
    anonymous
  end

  def self.list(page = nil)
    page = 1 if page.nil?
    self.page(page.to_i).order("created_at DESC").to_a
  end

  # Wpisy audytu, które zalogowano dla użytkownika owner oraz w kontekście operacji na użytkowniku owner
  # Tutaj bez żadnych .includes() - dla relacji polimorficznych jest to wolne
  def self.list_by_owner_and_owner_as_subject(owner, page = nil)
    page = 1 if page.nil?
    self.where("user_id = ? OR (auditable_type = ? AND auditable_id = ?) OR (auditable_type = ? AND auditable_id = ?)", owner.id, User.name, owner.id, Auth.name, owner.auth.id).page(page.to_i).order("created_at DESC").to_a
  end
end