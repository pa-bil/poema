class PublicationsController < ApplicationController
  include Poema::FileUploadSession

  before_filter :load_data_show,   :only => [:show, :delete, :destroy]
  before_filter :load_data_new,    :only => [:new]
  before_filter :load_data_create, :only => [:create]
  before_filter :load_data_edit,   :only => [:edit]
  before_filter :load_data_update, :only => [:update] # W akcji :create i :update użytkownik ma możliwość zmiany kontenera
                                                      # publikacji, w tych akcjach kontenerem nie jest ten z URL
                                                      # lecz ten, który został podany w danych formularza


  before_filter :check_access

  # Filtrowanie dostępu do akcji kontrolera
  access_control do
    deny  :banned,    :to => [:new, :create, :edit, :update]

    allow :root
    allow :operator
    allow all,        :to => [:index, :show]

    allow :owner,     :of => :container, :to => [:new, :create]
    allow :owner,     :of => :publication, :to => [:edit, :update, :delete, :destroy]

    # To specjalna rola, w znaczeniu podobna do tej która znajduje się w ContainersController
    allow :granted_publication_creator, :at => :container, :to => [:new, :create]
  end

  # Pomocnicza metoda określająca role mające dostęp do zablokowanej publikacji
  access_control :access_to_prohibited?, :filter => false do
    allow :root
    allow :operator
    allow :owner,     :of => :publication
    allow :owner,     :of => :container
  end

  # Używane w widoku, steruje dostępnością akcji
  access_control :helper => :allow_actions? do
    allow :root
    allow :operator
    allow :owner,     :of => :publication
  end

  private

  def load_data_show
    @publication = Publication.find(params[:id])
    @container = @publication.container
  end

  def load_data_new
    @container = Container.find(params[:container_id])
    @publication = @container.publications.new
    @uploaded_file = UploadedFile.new
  end

  def load_data_create
    @container = Container.find(params[:publication][:container_id])
    @publication = @container.publications.new
    @uploaded_file = UploadedFile.new
  end

  def load_data_edit
    load_data_show
    @uploaded_file = UploadedFile.new
  end

  def load_data_update
    @container = Container.find(params[:publication][:container_id])
    @publication = Publication.find(params[:id])
    @uploaded_file = UploadedFile.new
  end

  def check_access
    return if @publication.can_show? || access_to_prohibited?
    raise Poema::Exception::NotFound
  end

  public

  # GET /publications/1
  # GET /publications/1.json
  def show
    add_alert I18n.t 'controller.publications.access_prohibited' unless @publication.can_show?

    @comment_allowed = Comment.allowed_by_commentable? @publication, session_user
    @comments = Comment.list @publication, params[:comments_page]
    @comments_stat = Comment.calculate_stats @publication if @publication.content_copyrights_owned?
    
    @uploaded_files = UploadedFile.list @publication
    @is_image_content_type = Poema::ContentType::is_image_content_type?(@publication.top_level_container.id)

    show_increment_counters

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @publication }
    end
  end

  # POST /publications
  # POST /publications.json
  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @publication, :notice => I18n.t('controller.publications.created') }
        format.json { render :json => @publication, :status => :created, :location => @publication }
      else
        format.html { render :action => "new" }
        format.json { render :json => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /publications/1
  # PUT /publications/1.json
  def update
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @publication, :notice => I18n.t('controller.publications.updated') }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete
    respond_to do |format|
      format.html
      format.ajax
      format.json { render :json => @publication }
    end
  end

  # DELETE /publications/1
  # DELETE /publications/1.json
  def destroy
    respond_to do |format|
      if destroy_record
        format.html { redirect_to @container, :notice =>  I18n.t('controller.publications.destroyed') }
        format.json { head :ok }
      else
        format.html { render :action => "delete" }
        format.ajax { render :action => "delete" }
        format.json { render :json => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def destroy_record
#    perform_in_transaction do
      @publication.audit_params({:user => session_user, :ip => session_ip})
      @publication.destroy
#    end
  end

  def create_or_update_record
    perform_in_transaction do
      new_record = @publication.new_record?

      @publication.owner = session_user if new_record
      @publication.check_publications_limit = !(session_user.has_role?(:root) || session_user.has_role?(:operator))

      @publication.assign_attributes(params[:publication])
      @publication.audit_params({:user => session_user, :ip => session_ip})
      @publication.save!

      unless (session_file = get_file_session).nil?
        @uploaded_file = session_user.owned_uploaded_files.new
        persist_destroy_file_session(session_file, @uploaded_file, @publication, ContentCopyright.find(Poema::StaticId::get(:content_copyright, :dontknow)), true)
      end

      StatCounterObject.increment_counter :publication if new_record
    end
  end

  def show_increment_counters
    @publication.view_counter_increment

    StatCounterObject.increment_counter 'view'
    StatCounterObject.increment_counter 'view_ct_' + (Poema::ContentType::content_type_by_container_id(@container.top_level_container.id).nil? ? 'library' : 'owned')
  end
end
