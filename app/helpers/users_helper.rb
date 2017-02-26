# encoding: utf-8
module UsersHelper
  # To jest wrapper na link_to user, który maskuje usuniete konta uzytkowników
  def link_to_user(title, user)
    (user.deleted? || user.anonymous?) ? title : (link_to title, user)
  end

  # Metoda zwraca wizytówkę użytkownika na podstawie obiektu kontekstu który ma relację :owner
  def card(context, size = UploadedFile::AVATAR_DIM)
    raise "Invalid context #{context.class.name}, it must suport :owner association" unless context.respond_to? :owner

    if size <= UploadedFile::THUMB_DIM
      type = :thumb
    elsif size <= UploadedFile::AVATAR_DIM
      type = :avatar
    else
      type = :big
    end

    locals = {
      :context => context,
      :size    => size,
      :type    => type,
      :user    => context.owner
    }

    render :partial => 'users/card', :locals => locals
  end

  def user_image_url(user, size = 160, type = :avatar)
    if user.avatar.nil?
       gravatar_url(user.email, size)
     else
       user.avatar.url(type)
    end
  end

  def user_avatar_small_tag(user, size = UploadedFile::THUMB_DIM, params = {}, type = :thumb)
    params = {:title => user.name, :size => "#{size}x#{size}"}.merge(params)
    image_tag(user_image_url(user, size, type), params)
  end

  def user_image_tag(user, size = 160, params = {}, type = :avatar)
    params = {:title => user.name, :size => "#{size}x#{size}"}.merge(params)
    image_tag(user_image_url(user, size, type), params)
  end

  def gravatar_url(email, size = 160)
    hash = Digest::MD5.hexdigest(email)
    proto = (ssl_connection? ? 'https' : 'http')
    url = "#{proto}://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
    url_for(url)
  end

  # Metoda generuje content z gwiazdkami na podstawie wyliczonej rangi
  def img_user_rank(user)
    rank = user.rank.rank
    repeat = 1
    if rank < 10
      img = 1
      repeat = rank
    elsif rank < 100
      img = 2
      repeat = (rank.to_f/10).floor
    elsif rank < 1000
      img = 3
      repeat = (rank.to_f/100).floor
    elsif rank < 10000
      img = 4
      repeat = (rank.to_f/1000).floor
    elsif rank < 100000
      img = 5
      repeat = (rank.to_f/10000).floor
    elsif rank >= 100000
      img = 6
      repeat = 1
    end
    repeat = 1 if (repeat <= 0)
    version = 2
    raw (image_tag "i/rank/#{version}-#{img}.png") * repeat
  end

  def privacy_allow_show_details(*args, &block)
    viewer = args.shift
    owner = args.shift
    allow = privacy_allow_show_details?(viewer, owner)
    if block_given? && allow
       capture(&block)
    end
  end

  def user_update_log_to_human(log)
    case log.field_name
      when 'name'
        "Imię, nazwisko lub nick"
      when 'email'
        "Adres email"
      else
        raise "Unknown field name"
    end
  end
end