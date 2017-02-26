class SessionController < ApplicationController
  include Poema::FileUploadSession

  # skip_before_filter :https_to_http_redirect                        # nie wykonuj przekierowania na http, jeśli jestem na https (see force_ssl)
  # force_ssl :if => :ssl_configured?

  skip_before_filter :session_user_redirect_if_terms_not_current    # pozwól się zalogować użytkownikowi bez akceptacji nowego regulaminu

  before_filter :load_data

  access_control do
    allow anonymous,  :to => [:login, :authenticate_via_login_pass, :authenticate_via_omniauth]
    allow logged_in,  :to => [:logout]
  end

  protected

  def load_data
    @session_login = SessionLoginForm.new
    @session_oauth = SessionOmniauthForm.new
  end

  public

  def login
    save_redirect_from_referer_url(params[:automated] ? false : true)
  end

  def authenticate_via_login_pass
    @session_login = SessionLoginForm.new(params[:session_login_form].delete_if {|k, v|  !(%w[login password]).include?(k) })

    unless (a = Auth.find_by_login(@session_login.login)).nil?
      @session_login.auth = a
      @session_login.user = a.users.first
    end

    if @session_login.valid?
      perform_auth(@session_login.user)

      add_notice I18n.t('controller.session.login.success')
      redirect_to get_truncate_redirect
    else
      a.audit!({:user => @session_login.user, :ip => session_ip, :event_type => Audit::EVENT_AUTH, :level => Audit::LEVEL_NOTICE, :description => "Failed login"}) if @session_login.user
      render :action => "login"
    end
  end

  def authenticate_via_omniauth
    oauth = request.env["omniauth.auth"]
    case oauth[:provider]
      when 'nk'
        a = Auth.find_by_nk_id(oauth[:uid])
      when 'facebook'
        a = Auth.find_by_fb_id(oauth[:uid])
      else
        raise "Unknown OmniAuth provider #{oauth[:provider]}"
    end

    if a.nil?
      # Nie ma konta powiązanego z identyfikatorem z zewnętrznej usługi, zapisuję dane w sesji i przekierowuję do signupu
      # User uzupełni sobie dane i doda konto
      session[:authenticated_omniauth] = oauth

      add_notice I18n.t "controller.session.login.goto_signup"
      redirect_to new_signup_url
    else
      @session_oauth.auth = a
      @session_oauth.user = a.users.first

      if @session_oauth.valid?
        perform_auth(@session_oauth.user)

        add_notice I18n.t('controller.session.login.success')
        redirect_to get_truncate_redirect
      else
        a.audit!({:user => @session_oauth.user, :ip => session_ip, :event_type => Audit::EVENT_AUTH, :level => Audit::LEVEL_NOTICE, :description => "Failed login"}) if @session_oauth.user
        render :action => "login"
      end
    end
  end

  def logout
    # Zapisz datę wylogowania jako czas aktualnej wizyty, po ponownym zalogowaniu zostanie ona użyta jako czas ostatniej wizyty na stronie
    perform_in_transaction do
      s = session_user.stat
      s.current_visit = DateTime.current
      s.save!
    end

    # Wywal wszystkie dane z sesji niezależnie od wyniku aktualizacji danych powyżej
    session[:authenticated_user_id] = session[:authenticated_omniauth] = nil
    reset_session

    begin
      add_notice I18n.t 'controller.session.logout.success'
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to root_url
    end
  end

  private

  def perform_auth(u)
    a = u.auth
    a.audit!({:user => u, :ip => session_ip, :event_type => Audit::EVENT_AUTH, :description => "Log in"})

    s = u.stat

    # Przed aktualizacjami dat w current_visit mam prawdziwą datę ostatniego logowania
    # aktualizuje liczniki częstotliwości logowania
    dist = (DateTime.current.mjd - s.current_visit.to_datetime.mjd).to_i
    if dist < 1
      StatCounterObject.increment_counter :login_1
    elsif dist < 3
      StatCounterObject.increment_counter :login_3
    elsif dist < 7
      StatCounterObject.increment_counter :login_7
    elsif dist < 30
      StatCounterObject.increment_counter :login_30
    else
      StatCounterObject.increment_counter :login_more
    end

    # last_visit mówi kiedy user logował się ostatni raz. Na aktualizację nałożona jest UserStat::LAST_VISIT_TRIGGER_IN_HOURS
    # histereza (uaktualniam tylko wtedy, gdy ostatnia wizyta była więcej niż 12 godzin temu) po to, aby szybkie logowanie->wylogowanie
    # nie gubiło userowi dodanych aplikacji. W momencie logowania current_visit zawiera datę ostatniego faktycznego logowania
    s.last_visit = s.current_visit if s.current_visit <= UserStat::LAST_VISIT_TRIGGER.hours.ago

    # i wreszcie można ustawić czas ostatniej aktywności na bieżący
    s.current_visit = DateTime.current
    s.save!

    Auth.increment_counter :counter_login, a.id    
    StatCounterObject.increment_counter :login

    if a.crypt != Auth::DEFAULT_CRYPT && !params[:password].nil?
      a.crypt = Auth::DEFAULT_CRYPT
      a.password = params[:password]
      a.save!
    end

    # Przed ustawieniem identyfikatora użytkownika w sesji, zresetuj ją, po posprząta śmieci po poprzednich użytkownikach
    # przy czym trzeba przepisać do nowej sesji adres przekierowania
    url = get_redirect
    reset_session

    set_redirect url
    session[:authenticated_user_id] = u.id
  end
end
