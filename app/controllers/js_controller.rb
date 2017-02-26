class JsController < ApplicationController
  include Poema::FileUploadSession

  # Nie przekierowuj na HTTP, backendy JS używane mogą być w różnych kontekstach
  skip_before_filter :https_to_http_redirect

  access_control do
    allow all,       :to => [:index, :set_state, :get_state, :autocomplete_dict_localisation, :file_upload_session, :file_get_session]
    allow :user,     :to => [:autocomplete_roles]
  end

  USER_STATE_SESSION_PREFIX = "user_state_"

  respond_to :json

  def index
    raise Poema::Exception::NotFound
  end

  def file_upload_session
    errors = []
    errors << 'file not given' if params[:file].nil?
    if params[:file]
      errors << 'File is too small' if params[:file].tempfile.size < 1
      errors << 'File id too big' if params[:file].tempfile.size > 200.kilobytes
      errors << 'Unsupported content type' unless %w(image/jpeg image/png image/gif).include?(params[:file].content_type)
    end
    if errors.empty?
      save_file_session(params[:file])
    end

    render :json => {:result => errors.empty?, :errors => errors}.to_json
  end

  def file_get_session
    file = get_file_session_avatar
    raise Poema::Exception::NotFound if file.nil?

    # Trzeba wysłać nagłówek wygaszający plik, przegladarki (eg. Opera) keszują to długo, bo nie zmienia sie nazwa
    response.headers["Expires"] = DateTime.current.httpdate

    send_data(file[:content], {:type => file[:type], :filename => file[:filename], :disposition => 'inline'})
  end

  def set_state
    raise Poema::Exception::NotFound if params[:namespace].nil?

    namespace = USER_STATE_SESSION_PREFIX + params[:namespace]
    value = params[:value]
    session[namespace] = value
    render :json => {:result => true, :errors => []}.to_json
  end
  
  def get_state
    raise Poema::Exception::NotFound if params[:namespace].nil?

    namespace = USER_STATE_SESSION_PREFIX + params[:namespace]
    value = session[namespace]
    render :json => {:total => (value.nil? ? 0 : 1), :offset => 0, :results => value}.to_json
  end
  
  def autocomplete_roles
    result = []

    query = params[:q] ? (params[:q].to_s + '%') : ''
    where = "authorizable_type IS NULL AND authorizable_id IS NULL AND (name LIKE :name OR description LIKE :name OR id = :name)"
    Role.select("id, name, description").where(where, {:name => query}).each do |c|
        result.push({:id => c.id, :name => c.name, :description => c.description})
      end
    render :json => {:total => result.count, :offset => 0, :results => result}.to_json
  end

  def autocomplete_dict_localisation
    result = []
    query = params[:q] ? (params[:q].to_s + '%') : ''
    fields = "*, dict_countries.id AS country_id, dict_provinces.id AS province_id, dict_cities.id AS city_id"
    where = "dict_cities.city LIKE :name"
    DictCity.select(fields).joins(:dict_province, :dict_country).where(where, {:name => query}).each do |c|
        result.push({:id => c.city_id, :city => c.city, :country_id => c.country_id, :country => c.country, :province_id => c.province_id, :province => c.province})
      end
    render :json => {:total => result.count, :offset => 0, :results => result}.to_json
  end
end
