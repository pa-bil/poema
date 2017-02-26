class SignupController < ApplicationController
  include Poema::FileUploadSession

  # Wymuszaj signup po SSLu
  # skip_before_filter :https_to_http_redirect
  # force_ssl :only => [:new, :create], :if => :ssl_configured?

  access_control do
    allow anonymous
  end

  attr_writer :current_step

  def steps
    if has_omniauth_data?
      %w[personal contact localisation settings confirmation]
    else
      %w[intro personal contact localisation settings auth confirmation]
    end

  end

  def current_step
    @current_step || steps.first
  end

  def next_step
    self.current_step = steps[steps.index(current_step)+1]
  end

  def previous_step
    self.current_step = steps[steps.index(current_step)-1]
  end

  def first_step?
    current_step == steps.first
  end

  def last_step?
    current_step == steps.last
  end

  def new
    init_session

    if has_omniauth_data?
      o_data = get_omniauth_signup_data
      o_data[:user].each do |param,value|
        session[:signup_params_user]["#{param}"] = value if session[:signup_params_user]["#{param}"].nil?
      end
      o_data[:auth].each do |param,value|
        session[:signup_params_auth]["#{param}"] = value if session[:signup_params_auth]["#{param}"].nil?
      end
    end

    @user = User.new(session[:signup_params_user])
    @auth = Auth.new(session[:signup_params_auth])

    @first_step = first_step?
    @current_step = @user.section = @auth.section = session[:signup_step] = current_step

    @step_count = steps.count
    @step_number = (steps.index(@current_step) + 1)
  end

  def create
    init_session

    session[:signup_params_user].deep_merge!(params[:user]) if params[:user]
    session[:signup_params_auth].deep_merge!(params[:auth]) if params[:auth]

    r = false
    @auth = Auth.new(session[:signup_params_auth])
    @user = User.new(session[:signup_params_user])

    self.current_step = @current_step = @user.section = @auth.section = session[:signup_step]

    if @user.valid? && @auth.valid?
      if params[:back_button]
        previous_step
      elsif last_step?
        if @user.all_valid? && @auth.all_valid?
          r = perform_signup @auth, @user, get_file_session
        end
      else
        next_step
      end
      session[:signup_step] = self.current_step
    end

    if @user.new_record?
      @first_step = first_step?
      @step_count = steps.count
      @step_number = (steps.index(@current_step) + 1)

      render :new
    elsif r
      clear_session
      destroy_file_session

      # Użytkownik mógł zostać automatycznie aktywowany w procesie signupu, sprawdź to na kopii obiektu
      # usera. Jeśli nie jest aktywny, przekieruj do informacji o konieczności aktywacji, jeśli jest
      # aktywny kieruj na stronę logowania (tak jak to robi aktywacja)

      if User.find(@user.id).locked?
        redirect_to complete_signup_url
      else
        set_redirect root_path
        add_notice I18n.t 'controller.signup.activation.done'

        redirect_to new_session_url + '?automated=true'
      end
    else
      add_alert I18n.t "controller.generic.exception"
      render :new
    end
  end

  def thanks
  end

  def activation
    begin
      ActiveRecord::Base.transaction do
        perform_activation params[:token]
      end
      add_notice I18n.t 'controller.signup.activation.done'
    rescue Poema::Exception::SignupActivationAlreadyActive
      add_alert I18n.t 'controller.signup.activation.alreadyactive'
    rescue ActiveRecord::RecordNotFound, Poema::Exception::NotFound
      add_alert I18n.t 'controller.signup.activation.invalid'
    end

    set_redirect root_path
    redirect_to new_session_url + '?automated=true'
  end

  private

  def init_session
    session[:signup_params_user] ||= {}
    session[:signup_params_auth] ||= {}

    session[:signup_step] ||= self.current_step
  end

  def clear_session
    session[:signup_step] = session[:signup_params_user] = session[:signup_params_auth] = session[:authenticated_omniauth] = nil
  end

  def perform_signup(auth, user, session_file)
    perform_in_transaction do

      # Zapisz dane z OmniAuth
      if has_omniauth_data?
        case get_omniauth_provider
          when 'nk'
            auth.nk_id = get_omniauth_uid
          when 'facebook'
            auth.fb_id = get_omniauth_uid
          else
            raise "Unknown OmniAuth provider #{session[:authenticated_omniauth][:provider]}"
        end
      end

      auth.save!

      user.auth = auth
      user.quota = PoemaConfig.default_quota_mb
      user.save!

      user.audit!({:user => user, :ip => session_ip, :event_type => Audit::EVENT_CREATE, :description => 'User signed-up for a new account'})

      tal = user.terms_accept_logs.build({:accepted => true, :terms_version => user.terms_version})
      tal.audit_params({:user => user, :ip => session_ip, :description => "User accepted current terms version"})
      tal.save!

      user.terms_accept_logs << tal

      # Dodaję avatar usera jeśli jakiś znajduje się w sesji
      unless session_file.nil?
        persist_file_session(session_file, user.owned_uploaded_files.new, user, ContentCopyright.find(Poema::StaticId::get(:content_copyright, :dontknow)), true)
      end

      StatCounterObject.increment_counter :signup_performed

      activation_token = SecureRandom.base64(128).gsub(/[^0-9a-z ]/i, '').slice(1..32)
      activation = user.create_user_signup_activation({:code => activation_token, :signup_on => DateTime.current})

      # Jeśli ktoś się logował za pośrednictwem FB/NK i nie mienił adresu email nie ma potrzeby potwierdzania konta, adres email jest
      # już zweryfikowany u nich, jeśli nie, wyślij mail z prośbą aktywacji
      if has_omniauth_data?
        if user.email == get_omniauth_email
          perform_activation activation_token, true
        else
          UserMailer.signup_activation(user, auth, activation, get_omniauth_provider).deliver
        end
      else
        UserMailer.signup_activation(user, auth, activation).deliver
      end
    end
  end

  def has_omniauth_data?
    session[:authenticated_omniauth] && session[:authenticated_omniauth].instance_of?(OmniAuth::AuthHash)
  end

  def get_omniauth_uid
    raise "OmniAuth data expected but missing" if !has_omniauth_data?
    session[:authenticated_omniauth][:uid]
  end

  def get_omniauth_provider
    raise "OmniAuth data expected but missing" if !has_omniauth_data?
    session[:authenticated_omniauth][:provider]
  end

  def get_omniauth_email
    raise "OmniAuth data expected but missing" if !has_omniauth_data?
    omniauth_hash = session[:authenticated_omniauth]
    omniauth_hash.info[:email]
  end

  def get_omniauth_signup_data
    raise "OmniAuth data expected but missing" if !has_omniauth_data?

    omniauth_hash = session[:authenticated_omniauth]

    info = omniauth_hash.info
    extended = omniauth_hash.extra.raw_info

    user = {}
    user[:name] = info[:name]
    user[:email]    = info[:email]

    # Login i pass wygenerujmy losowy, tak, zeby nie trzeba było go podawać, ukryję krok rejestracji
    auth = {}
    auth[:login] = SecureRandom.base64(128).gsub(/[^0-9a-z ]/i, '').slice(1..48)
    auth[:password] = SecureRandom.base64(254).gsub(/[^0-9a-z ]/i, '').slice(1..128)

    # FB gender trzyma w raw_info
    gender = info[:gender] if info[:gender]
    gender = extended[:gender] if extended[:gender]

    user[:gender]   = 'M' if gender == 'male'
    user[:gender]   = 'F' if gender == 'female'

    # Lokalizacje trzeba geokodować aby uzyskac znormalizowaną postać, dodatkowo FB
    # ma hometown, które można użyć jesli nie ma :location
    location = info[:location]
    location = extended[:hometown][:name] if !location && extended[:hometown]

    if location
      l = Poema::Geocode::precise(location)
      user[:localisation] = l unless l.nil?
    end

    if info[:image]
      begin
        save_file_session_from_net(info[:image])
      rescue Exception => e
        e.inspect
      end
    end

    user[:website] = extended[:website] if extended[:website]
    {:user => user, :auth => auth}
  end

  def perform_activation(activation_code, auto = false)
    a = UserSignupActivation.find_by_code! activation_code

    raise Poema::Exception::SignupActivationAlreadyActive.new unless a.activation_on.nil?

    # Odblokować konto usera i ustawić nu quotę na domyślną
    # Konto może być usunięte (nil)
    u = a.user
    raise Poema::Exception::NotFound if u.nil?

    u.audit_params({:user => u, :ip => session_ip, :description => (auto ? "User's account was auto confirmed because of registration from trusted source" : 'User confirmed account')})
    u.locked = false
    u.save!

    # Zamknąć aktywację
    a.activation_on = DateTime.current
    a.save!

    # Dodaj podstawowe role w serwisie
    u.assign_default_roles

    # Aktywacja signupu zlicza statystykę
    StatCounterObject.increment_counter :signup

    # Mail z informacjami
    UserMailer.signup_activated(u).deliver
  end
end
