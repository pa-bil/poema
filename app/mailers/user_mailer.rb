class UserMailer < ActionMailer::Base

  layout 'mail'

  helper :application, :static_page

  default :from => PoemaConfig.mail_automated_from
  default_url_options[:host] = PoemaConfig.site_hostname

  def signup_activation(user, auth, activation, omniauth_provider = nil)
    @user = user
    @auth = auth
    @activation = activation
    @omniauth_provider = omniauth_provider
    mail(:to => get_to(user), :subject => I18n.t('mailer.signup.activation.subject'))
  end

  def signup_activation_reminder(user)
    @user = user
    @auth = user.auth
    @activation = user.user_signup_activation
    @omniauth_provider = @auth.omniauth_provider
    mail(:to => get_to(user), :subject => I18n.t('mailer.signup.activation_reminder.subject'))
  end

  def signup_activated(user)
    @user = user
    mail(:to => get_to(user), :subject => I18n.t('mailer.signup.activated.subject'))
  end

  def password_reminder_create(password_reminder)
    @user = password_reminder.user
    @password_reminder = password_reminder
    mail(:to => "#{@user.name} <#{@password_reminder.email}>", :subject => I18n.t('mailer.password_reminder.create.subject'))
  end

  def password_reminder_destroy(password_reminder, password)
    @user = password_reminder.user
    @password = password
    mail(:to => "#{@user.name} <#{password_reminder.email}>", :subject => I18n.t('mailer.password_reminder.create.subject'))
  end

  def ban_created(moderation)
    @moderation = moderation
    @user = moderation.user
    mail(:from => PoemaConfig.mail_personalized_from, :to => get_to(@user), :subject => I18n.t('mailer.moderation.ban.user_created'))
  end

  def ban_reverted(user)
    @user = user
    mail(:from => PoemaConfig.mail_personalized_from, :to => get_to(@user), :subject => I18n.t('mailer.moderation.ban.user_reverted'))
  end

  def ban_expired(moderation, user)
    @moderation = moderation
    @user = user
    mail(:from => PoemaConfig.mail_personalized_from, :to => get_to(@user), :subject => I18n.t('mailer.moderation.ban.user_expired'))
  end

  def new_comment_arrived(commentable, comment)
    return unless commentable.respond_to?(:owner)

    @commentable = commentable
    @user = commentable.owner

    # może być nil (user anonimowy), przypisuję do nowego obiektu usera nazwę i mail z komentarza
    if comment.owner.nil?
      @commentator = User.new({:name => comment.name, :email => comment.email})
    else
      @commentator = comment.owner
    end

    mail(:to => get_to(@user), :reply_to => get_to(@commentator), :subject => I18n.t('mailer.comment.recived.subject')).deliver if can_send_mail?(@commentator, @user)
  end

  def account_self_destroy(user)
    @user = user
    mail(:to => get_to(@user), :subject => I18n.t('mailer.account.removed')).deliver
  end

  def account_administrative_destroy(user, personal_data_removed = false)
    @user = user
    @personal_data_removed = personal_data_removed
    mail(:from => PoemaConfig.mail_personalized_from, :to => get_to(@user), :subject => I18n.t('mailer.account.removed')).deliver
  end

  private

  def can_send_mail?(from, to)
    return (from.id != to.id && true == to.sendmails? && to.email.to_s.length > 0)
  end

  def get_to(user)
    # Z nazwy użytkownika trzeba pozbyć się wszelkich śmieci, które zdeformują adres odbiorcy
    # Zrobiłbym to regexpem na a-z, ale nadal chciałbym tu mieć znaki diakrytyczne
    return user.name.tr('!@#$%^&*(){}[]:;<>?,.','') + " <#{user.email}>"
  end
end
