class UploadedFile < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_authorization_object
  acts_as_auditable

  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to :content_object, :foreign_key => :uploadable_type
  belongs_to :uploadable, :polymorphic => true

  belongs_to :content_copyright

  has_one :user
  has_one :search_index, :as => :searchable

  def storage_zone
    (user_id % 16).to_s.rjust(2,'0') + '/' + (user_id % 256).to_s.rjust(3,'0')
  end

  def filestore_url
    '/filestore'
  end

  def filestore_path
    PoemaConfig.filestore_path.nil? ? Rails.root.to_s + '/public/filestore/' + storage_zone + "/:hash.:extension" : PoemaConfig.filestore_path + '/' +storage_zone + "/:hash.:extension"
  end

  MAX_SIZE = 750.kilobytes

  AVATAR_DIM = 160
  THUMB_DIM  = 85

  @file_u  = lambda do |a|
    raise "Unable to detect filestore url because of missing user" if a.instance.user_id.nil?
    raise "Missing storage URL" if a.instance.filestore_url.nil?
    a.instance.filestore_url + '/' + a.instance.storage_zone + "/:hash.:extension"
  end

  @file_p = lambda do |a|
    raise "Unable to detect filestore path because of missing user" if a.instance.user_id.nil?
    raise "Storage path is unknown" if a.instance.filestore_path.nil?
    a.instance.filestore_path
  end

  has_attached_file :file,
                    :hash_secret => "Hilooy8aRahBieB7Eah0iLah",
                    :styles => {:avatar => "#{AVATAR_DIM}x#{AVATAR_DIM}#", :thumb => "#{THUMB_DIM}x#{THUMB_DIM}#", :big => "720x540>"},
                    :url => @file_u,
                    :path => @file_p

  validates_with UploadedFileUserQuotaValidator
  validates_with ContentCopyrightValidator

  validates_attachment_presence     :file
  validates_attachment_size         :file,
                                    :less_than => MAX_SIZE
  validates_attachment_content_type :file,
                                    :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']

  attr_writer :is_avatar

  attr_accessible :is_avatar, :content_copyright_id, :file, :description

  before_post_process :should_process?

  def is_avatar
    @is_avatar
  end

  def is_avatar?
    false == @is_avatar.nil? && 1 == @is_avatar.to_i
  end

  def path(style = :original)
    file.path style
  end

  def url(style = :original)
    file.url style
  end

  @where_conditions = {:deleted_at => nil}

  # Zwraca listę wszystkich plików, bez względu na status praw autorskich, powinno być
  # używane wyłącznie w manelach administracyjnych
  def self.list_all(uploadable)
    uploadable.uploaded_files.where(@where_conditions).to_a
  end

  # To jest lista plików powiązanych z podanym kontekstem
  def self.list(uploadable)
    uploadable.uploaded_files.where(@where_conditions.merge({'content_copyrights.prohibit_exposition' => false})).joins(:content_copyright).to_a
  end

  def self.list_by_owner(user)
    user.owned_uploaded_files.where(@where_conditions).to_a
  end

  def self.get_sum_of_uploaded_files(user)
    uploaded = self.where(:user_id => user.id).select("SUM(file_file_size) AS s").group(:user_id).first
    uploaded.nil? ? 0 : uploaded.s.to_i
  end

  def self.get_percent_od_user_space(user)
    quota = user.quota.megabytes.to_f
    sum = self.get_sum_of_uploaded_files(user).bytes.to_f
    ((sum/quota)*100)
  end

  def can_show?
    !destroyed? && !content_copyright.prohibit_exposition?
  end

  def search_index_content
    [self.description] if (!self.description.nil? && self.can_show?)
  end

  private

  def should_process?
    ENV['MIGRATION'] ? false : true
  end
end
