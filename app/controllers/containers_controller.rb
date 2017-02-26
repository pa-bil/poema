class ContainersController < ApplicationController

  before_filter :load_data
  before_filter :check_access

  access_control do
    deny  :banned,   :to => [:new, :create, :edit, :update]

    allow :root
    allow :operator
    allow all,       :to => [:index, :show, :index_publications_last]
    allow logged_in, :to => [:index_publications_since, :picker]

    allow :owner,    :of => :parent_container, :to => [:new, :create]
    allow :owner,    :of => :container, :to => [:edit, :update, :delete, :destroy]

    # To jest specjalna rola obsługiwana via User.has_role?, w sktócie kontener ma pole granted_container_creator_role_id
    # które zawiera identyfikator roli, co przekłada się na użycie tej roli w miejscu :granted_container_creator
    allow :granted_container_creator, :at => :parent_container, :to => [:new, :create]
  end

  # Pomocnicza metoda określająca role mające dostęp do zablokowanego kontenera
  access_control :access_to_prohibited?, :filter => false do
    allow :root
    allow :operator
    allow :owner,    :of => :container
    allow :owner,    :of => :parent_container  # To tylko po to, aby można było utworzyć kontener wewnątrz niewidocznego
                                               # kontenera którego się jest właścicielem.
  end

  # Używane w widoku, steruje dostępnością akcji
  access_control :helper => :allow_actions? do
    allow :root
    allow :operator
    allow :owner,    :of => :container
  end

  access_control :helper => :allow_actions_create? do
    allow :root
    allow :operator
    allow :owner,    :of => :container
    allow :granted_container_creator, :at => :container
  end

  access_control :helper => :allow_actions_publish? do
    allow :root
    allow :operator
    allow :owner,    :of => :container
    allow :granted_publication_creator, :at => :container
  end

  private

  def load_data
    if params[:id].nil?
      if params[:container_id].nil?
        @parent_container = Container.new
        @container = Container.new
      else
        @parent_container = Container.find(params[:container_id])
        @container = @parent_container.containers.new
      end
    else
      @container = Container.find(params[:id])

      @parent_container = @container.container
      @parent_container = Container.new if @parent_container.nil? # To jest potrzebne przy kontenerach 1-go poziomu, nie
                                                                  # mają one parenta, więc będzie nil, a na nil'u przechodzi ACL
    end
  end

  def check_access
    return if @container.can_show? || access_to_prohibited?
    raise Poema::Exception::NotFound
  end

  public

  # GET /containers
  # GET /containers.json
  def index
    @containers = Container.list_top_level true, params[:containers_sort]
    respond_to do |format|
      format.html
      format.json { render :json => @containers }
    end
  end

  def index_publications_last
    # Wyświetlam tylko pierwsze 50 (Publication.per_page) publikacji, nie więcej
    since = (@container.last_publication.nil? || @container.last_publication + 30.days < DateTime.current) ? 30.days.ago : (@container.last_publication - 30.days)
    @publications = filter_publication_by_container Publication.list_by_published_at(since, 1), @container
  end

  def index_publications_since

    # Tutaj nie można zrobić paginacji w zapytaniu, ponieważ limituje po wszystkich wynikach
    # a ja jeszcze nie wiem który z rekordów wyświetlę
    @publications = filter_publication_by_container Publication.list_by_published_at(session_user.stat.last_visit_trimmed), @container
  end

  # GET /containers/1
  # GET /containers/1.json
  def show
    add_alert I18n.t('controller.containers.access_prohibited') unless @container.can_show?
    add_alert I18n.t('controller.containers.empty') if @container.counter_publication < 1

    @containers = Container.list @container, params[:containers_sort], params[:include_empty]
    @publications = Publication.list @container, params[:publications_sort]
    @comments = Comment.list @container, params[:comments_page]

    @comment_allowed = Comment.allowed_by_commentable? @container, session_user
    @uploaded_files = UploadedFile.list @container

    show_increment_counters

    respond_to do |format|
      format.html
      format.json { render :json => {:element => @container, :containers => @containers, :publications => @publications}}
    end
  end

  # GET /containers/new
  # GET /containers/new.json
  def new
    respond_to do |format|
      format.html
      format.json { render :json => @container }
    end
  end

  # GET /containers/1/edit
  def edit
    @grant_containers_role = Role.find(@container.granted_container_creator_role_id) unless @container.granted_container_creator_role_id.nil?
    @grant_publications_role = Role.find(@container.granted_publication_creator_role_id) unless @container.granted_publication_creator_role_id.nil?
  end

  # POST /containers
  # POST /containers.json
  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @container, :notice => I18n.t('controller.containers.created') }
        format.json { render :json => @container, :status => :created, :location => @container }
      else
        format.html { render :action => "new" }
        format.json { render :json => @container.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /containers/1
  # PUT /containers/1.json
  def update
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @container, :notice => I18n.t('controller.containers.updated') }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @container.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete
    respond_to do |format|
      format.html
      format.ajax { render 'delete.ajax' }
      format.json { render :json => @publication }
    end
  end

  # DELETE /containers/1
  # DELETE /containers/1.json
  def destroy
    redirect = @container.container.nil? ? containers_url : @container.container
    ActiveRecord::Base.transaction do
      @container.audit_params({:user => session_user, :ip => session_ip})
      @container.destroy
    end
    respond_to do |format|
      format.html { redirect_to redirect, :notice =>  I18n.t('controller.containers.destroyed') }
      format.json { head :ok }
    end
  end

  def picker
    if params[:id]
      c = Container.find(params[:id])
      @containers = Container.list c, Poema::SortOptions::SORT_BY_TITLE, true
      @level_up_container = c.container
    else
      @containers = Container.list_top_level false, Poema::SortOptions::SORT_BY_TITLE
      @level_up_container = nil
    end

    respond_to do |format|
      format.html { raise Poema::Exception::NotFound }
      format.ajax
    end
  end

  private

  def create_or_update_record
    perform_in_transaction do
      new_record = @container.new_record?

      @container.owner = session_user if new_record

      @container.assign_attributes(params[:container], :as => session_user_assign_attributes_as(:root, :operator))
      @container.audit_params({:user => session_user, :ip => session_ip})
      @container.save!

      StatCounterObject.increment_counter :container if new_record
    end
  end

  def filter_publication_by_container(publications, container)
    result = []
    publications.each{|p| 
      if p.container.parents.map{|c| c.id}.include?(container.id)
        result.push(p)
      end
    }
    result
  end

  def show_increment_counters
    @container.view_counter_increment

    StatCounterObject.increment_counter 'view'
    StatCounterObject.increment_counter 'view_ct_' + (Poema::ContentType::content_type_by_container_id(@container.top_level_container.id).nil? ? 'library' : 'owned')
  end
end
