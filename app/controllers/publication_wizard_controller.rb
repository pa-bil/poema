class PublicationWizardController < ApplicationController
  access_control do
    deny  :banned
    allow :user
  end

  def content_type_save
    ct = params[:content_type].to_i
    pm = Poema::ContentType::publication_mode_by_content_type(ct)
    case pm
      when Poema::ContentType::PUBLISH_CONTAINER
        user = session_user
        @ucs = user_containers(user, ct)
        if @ucs.empty?
          perform_in_transaction do
            uc = auto_sub(user, user.name, ct)
            uc = auto_sub(user, user.auth.login, ct) if uc.nil?
            @ucs.push(uc) unless uc.nil?
          end
        end
        if @ucs.empty?
          raise Poema::Exception::NotFound
        elsif @ucs.count == 1
          redirect_to_with_marker new_container_publication_url(@ucs.first)
        else
          render :choose_container
        end
      when Poema::ContentType::PUBLISH_CALENDAR
        redirect_to_with_marker new_calendar_url
      else
        raise Poema::Exception::NotFound
    end
  end

  def choose_container_save
    redirect_to_with_marker new_container_publication_url(Container.find(params[:container_id]))
  end

  private

  def redirect_to_with_marker(url)
    redirect_to url + '?publication_wizard=1'
  end

  def title_to_tc_title(title)
    first_letter = title.strip[0,1]
    (first_letter =~ /[A-Za-z]/).nil? ? 'Misc' : first_letter.upcase
  end

  def user_containers(user, content_type)
    # ponieważ nie wiemy w której z literek (master_children_ids) kontenera dla danego typu publikacji (master)
    # user ma folder (mógł zmienić nicka, i nie trafimy po pierwszej literce) musimy szukać we wszystkich literkach
    master = Container.find(Poema::ContentType::container_id_by_content_type(content_type))
    master_children_ids = master.containers.select(:id).where(:deleted_at => nil).map {|r| r.id }
    Container.where(:container_id => master_children_ids, :user_id => user.id, :deleted_at => nil).to_a
  end

  def auto_sub(user, title, content_type)
    tc_title = title_to_tc_title(title)
    master = Container.find(Poema::ContentType::container_id_by_content_type(content_type))

    # Szukam lub tworzę jeśli nie ma kontener z literką usera (A/B/C...)
    # Właścicielem kontenera jest root
    tc = master.containers.where({:deleted_at => nil, :title => tc_title}).first
    if tc.nil?
      tc = User.find(Poema::StaticId::get :user, :root).owned_containers.new
      tc.assign_attributes({:title => tc_title, :sort => Container::SORT_BY_TITLE}, :as => :user)
      tc.audit_params({:user => session_user, :ip => session_ip, :description => "Auto-created via publication wizard"})
      master.containers << tc
      tc.save!
    end

    # W kontenerze z literką, tworzę docelowy katalog usera
    title = title.split(' ').each{|word| word.capitalize!}.join(' ')
    if tc.containers.where({:deleted_at => nil, :title => title}).empty?
      uc = user.owned_containers.new
      uc.assign_attributes({:title => title, :sort => Container::SORT_BY_DATE}, :as => :user)
      uc.audit_params({:user => session_user, :ip => session_ip, :description => "Auto-created via publication wizard"})
      tc.containers << uc
      uc.save!
      uc
    else
      nil
    end
  end
end