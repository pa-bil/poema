class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all

  helper_method :session_user
  helper_method :current_user
  helper_method :session_user?
  helper_method :ssl_connection?
  helper_method :version
  helper_method :current_controller_action
  helper_method :money_donation_action

  # Wyjątki dotyczące braku uprawnień, przy czym stan sesji jest nieznany, i powinna nastąpić próba podniesienia uprawnień
  rescue_from Acl9::AccessDenied,              :with => :access_denied
  rescue_from Poema::Exception::AuthRequired,  :with => :access_denied

  # Wyjątek dotyczący całkowitego braku dostępu (403)
  rescue_from Poema::Exception::AccessDenied,  :with => :access_denied_permanently

  # Wyjątki dotyczące nieodnalezionych danych (404)
  rescue_from ActiveRecord::RecordNotFound,    :with => :not_found
  rescue_from Poema::Exception::NotFound,      :with => :not_found
  rescue_from ActionView::MissingTemplate,     :with => :not_found

# before_filter :https_to_http_redirect

  before_filter :rendering_time_init
  before_filter :session_user_load
  before_filter :session_user_banned_alert
  before_filter :session_user_redirect_if_terms_not_current

  around_filter :pass_request_info

  protected

  def money_donation_action
    begin
      MoneyDonationAction.find(1)
    rescue
      nil
    end
  end

  def current_controller_action
    (params[:controller].gsub(/\//, '-') + '-' + action_name) .downcase.gsub(/_/, '-')
  end

  def version
    RUBY_VERSION.to_s
  end

  def ssl_connection?
    request.ssl?
  end

  def ssl_configured?
    Rails.env.production?
  end

  def perform_in_transaction
    begin
      ActiveRecord::Base.transaction do
        yield
      end
      r = true
    rescue ActiveRecord::RecordInvalid
      r = false
    rescue Exception => e
      raise e if (Rails.env == 'development' || Rails.env == 'staging')

      logger.fatal e.to_s
      r = false
    end
    r
  end

  # Przekieruj na http jeśli jestem na https
  def https_to_http_redirect
    redirect_to :protocol => 'http://', :status => :moved_permanently if request.ssl?
  end

  # Pomiar czasu renderowania strony, używany w layoucie
  def rendering_time_init
    @rendering_start_time = Time.now.usec
  end

  # Metoda obsługuje wiele alertów jednocześnie
  def flash_message(text, type)
    flash[type] ||= []
    flash[type].each do |a|
      return if a == text
    end
    flash[type] << text
  end

  def add_notice(text)
    flash_message(text, :notice)
  end

  def add_alert(text)
    flash_message(text, :alert)
  end

  # Ta metoda, osadzona dynamicznie, poinformuje wszystkie modele, że są wywoływane z poziomu żądania HTTP
  # (to jest potrzebne, aby eg. poprawnie walidować rekordy audytu)
  def pass_request_info
    klasses = [ActiveRecord::Base, ActiveRecord::Base.class]
    klasses.each do |klass|
      klass.send(:define_method, "is_http_request", proc { true })
    end
    yield
  end

  def skip_session
    request.session_options[:skip] = true
  end

  # Sprawdzamy status sesji użytkownika, jeśli jest jakiś zalogowany buduję instancje jego obiektu
  def session_user_load
    @session_user = nil
    if !session.nil? && !session[:authenticated_user_id].nil?
      @session_user = User.readonly.find_by_id(session[:authenticated_user_id])
    end
  end

  # Wywoływane jako before_filter: wyświetla stosowne powiadomienie o blokadzie konta dla zalogowanego
  # użytkownika
  def session_user_banned_alert
    add_alert I18n.t('controller.generic.authentication.yourebanned') if (!@session_user.nil? && (request.format && request.format.html?) && @session_user.banned?)
  end

  # Sprawdza czy aktualnie zalogowany użytkownik zaakceptował najnowszą wersję regulaminu, jeśli nie, robi
  # przekierowanie do strony, gdzie user może zaakceptować nową wersję
  def session_user_redirect_if_terms_not_current
    if session_user? && false == @session_user.terms_version.current?
      save_redirect_from_current_url
      add_alert I18n.t('controller.generic.terms.outdated')

      respond_to do |format|
        format.html { redirect_to new_term_terms_accept_url(TermsVersion.current!) }
        format.ajax { render :template => 'errors/page403', :status => :forbidden }
        format.json { render :json => '{"error": "Access denied"}', :status => :forbidden }
      end
    end
  end

  # Używane w widokach do identyfikacji zalogowanego usera
  access_control :helper => :logged_in? do
    allow logged_in
  end

  # Zwraca obiekt true jeśli mamy zalogowanego usera
  def session_user?
    (!@session_user.nil? && !@session_user.locked?)
  end

  # Zwraca obiekt zalogowanego usera
  def session_user
    @session_user if (!@session_user.nil? && !@session_user.locked?)
  end

  def session_ip
    request.headers['HTTP_CF_CONNECTING_IP'] || request.remote_ip
  end

  # Alias na session_user
  def current_user
    session_user
  end

  # Metoda zwraca klasę użytkownika używaną w metodzie assign_attributes, zalogowany i niezbanowany użytkownik zawsze
  # zwróci :user, użytkownik, który będzie posiadał jakąkolwiek z any_of_expected_roles ról zwróci :admin, w pozostałych
  # przypadkach mamy :anonymous
  def session_user_assign_attributes_as(*any_of_expected_roles)
    if session_user && !session_user.banned?
      return :admin if session_user.has_any_of_roles? any_of_expected_roles
      return :user
    end
    :anonymous
  end

  def access_denied_permanently
    respond_to do |format|
      format.html { render :template => 'errors/page403', :status => :forbidden }
      format.ajax { render :template => 'errors/page403', :status => :forbidden }
      format.json { render :json => '{"error": "Access denied"}', :status => :forbidden }
    end
  end

  def access_denied(e = nil)
    raise e if e && (Rails.env.development? || Rails.env.staging?)

    if session_user?
      access_denied_permanently
    else
      save_redirect_from_current_url
      add_notice I18n.t 'controller.generic.authentication.required'
      respond_to do |format|
        format.html { redirect_to new_session_url + '?automated=true' }
        format.ajax { render :template => 'errors/page401', :status => :unauthorized }
        format.json { render :json => '{"error": "Authorisation required"}', :status => :unauthorized }
      end
    end
  end

  def not_found(e = nil)
    raise e if e && (Rails.env.development? || Rails.env.staging?)

    respond_to do |format|
      format.html { render :template => 'errors/page404', :status => :not_found }
      format.ajax { render :template => 'errors/page404', :status => :not_found }
      format.json { render :json => '{"error": "Not found"}', :status => :not_found }
    end
  end

  def get_redirect
    session[:redirect_back] ? session[:redirect_back] : root_path
  end

  def set_redirect(url)
    session[:redirect_back] = url
  end

  def get_truncate_redirect
    url = get_redirect
    set_redirect nil
    url
  end

  def save_redirect_from_referer_url(overwrite = false)
    if session[:redirect_back].nil? || overwrite
      ref = request.referer
      if ref && (URI(ref).host.nil? || URI(ref).host.include?(PoemaConfig.site_hostname)) && URI(ref).path != URI(request.url).path
        set_redirect ref.gsub(/\.ajax|.json/, '')
      else
        set_redirect root_path
      end
    end
  end

  # To zawsze nadpisuje, używane przy przerwaniu nawigacji (brak uprawnień, nowy regulamin, etc)
  def save_redirect_from_current_url
    set_redirect request.url.gsub(/\.ajax|.json/, '')
  end
end
