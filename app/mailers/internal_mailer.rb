class InternalMailer < ActionMailer::Base

  helper :application, :static_page, :forum_threads

  default :from => PoemaConfig.mail_automated_from
  default_url_options[:host] = PoemaConfig.site_hostname

  def moderation_created(moderation, moderateable_context = nil)
    @moderator = moderation.moderator
    @moderation = moderation
    @moderateable_context = moderateable_context
    unless (@user = moderation.user).nil?
      @moderations_count = Moderation.count_uniq(@user)
    end

    mail(:to => PoemaConfig.mail_moderators_list, :subject => I18n.t('mailer.moderation.moderation.created'))
  end

  def moderation_reverted(moderator, moderateable, moderateable_context)
    @moderator = moderator
    @user = moderateable.owner
    @moderateable = moderateable
    @moderateable_context = moderateable_context
    mail(:to => PoemaConfig.mail_moderators_list, :subject => I18n.t('mailer.moderation.moderation.reverted'))
  end

  def ban_created(moderation)
    @moderation = moderation
    @moderator = moderation.moderator
    @user = moderation.user
    @moderations_count = Moderation.count_uniq(@user)
    mail(:to => PoemaConfig.mail_moderators_list, :subject => I18n.t('mailer.moderation.ban.created'))
  end

  def ban_reverted(moderator, user)
    @moderator = moderator
    @user = user
    mail(:to => PoemaConfig.mail_moderators_list, :subject => I18n.t('mailer.moderation.ban.reverted'))
  end

  def ban_expired(moderation, user)
    @user = user
    @moderation = moderation
    mail(:to => PoemaConfig.mail_moderators_list, :subject => I18n.t('mailer.moderation.ban.expired'))
  end
end
