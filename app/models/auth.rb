# encoding: utf-8
class Auth < ActiveRecord::Base
  nilify_blanks
  acts_as_paranoid
  acts_as_partial_validation
  acts_as_auditable

  has_many :users, :dependent => :destroy

  validates :login,
            :length => {:minimum => 3, :maximum => 48}, :format => {:with => /^[a-zęóąśłżźćń0-9.:*@()^!_-]+$/iu}, :uniqueness => {:case_sensitive => false},
            :if => lambda { |obj| obj.section? "auth" }
  validates :nk_id,
            :uniqueness => true, :allow_nil => true
  validates :fb_id,
            :uniqueness => true, :allow_nil => true
  validates :password,
            :length => {:minimum => 6, :maximum => 128}, :confirmation => true,
            :if => lambda { |obj| (obj.section? "auth") }

  attr_accessible :login, :password, :password_confirmation, :nk_id, :fb_id
  attr_accessor :password_require_hashing

  before_save :password_hash_if_required
  before_destroy :anonymize_personal_data

  SHA1          = 'SHA1'
  MD5           = 'MD5'
  OLD_MYSQL     = 'OLDMYSQL'

  DEFAULT_CRYPT = SHA1
  SALT          = 'uK2io2ohaej7AenaEhaiTho4iu0OhxikUkoo7NeiOom8equ9'

  def password_check(plain_password)
      password == password_hash(crypt, login, plain_password)
  end

  # login jest używany do solenia hasła, nie może się zmienić
  def login=(login)
    self.errors.add(:login, I18n.t('activerecord.errors.models.auth.attributes.login.ro')) unless self.new_record?
    write_attribute(:login, login)
  end

  def password_hash=(password)
    self.password_require_hashing = false
    write_attribute(:password, password)
  end

  def password=(password)
    self.password_require_hashing = true
    write_attribute(:password, password)
  end

  def crypt
    write_attribute(:crypt, DEFAULT_CRYPT) if read_attribute(:crypt).nil?
    super
  end

  #
  def omniauth_provider
    return 'facebook' unless fb_id.nil?
    return 'nk' unless nk_id.nil?
    nil
  end

  protected

  def password_hash_if_required
    if self.password_require_hashing
      self.password_require_hashing = false
      write_attribute(:password, password_hash(self.crypt, self.login, self.password))
    end
  end

  def password_hash(method, login, plain_password)
    case method
      when SHA1
        return Digest::SHA1.hexdigest(plain_password + login.downcase + SALT)
      when MD5
        return Digest::MD5.hexdigest(plain_password)
      when OLD_MYSQL
        return self.connection.select_all("SELECT OLD_PASSWORD(" + Auth.connection.quote(plain_password) + ") AS pass").first.fetch("pass")
      else
        raise "Unknown crypt type"
    end
  end

  def anonymize_personal_data
    self.attributes = {:nk_id => nil, :fb_id => nil}
    raise Exception "Failed to anonymize user's personal data" unless self.save(:validate => false)
  end
end
