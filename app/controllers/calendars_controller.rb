class CalendarsController < ApplicationController
  include Poema::FileUploadSession

  before_filter :load_data_show,   :only => [:show]
  before_filter :load_data_new,    :only => [:new, :create]
  before_filter :load_data_update, :only => [:edit, :update]

  before_filter :check_access, :except => [:index]

  access_control do
    deny  :banned,  :except => [:index, :show]

    allow :root
    allow :operator
    allow all,      :to => [:index, :show]
    allow :user,    :to => [:new, :create]
    allow :owner,   :of => :calendar, :to => [:edit, :update, :delete, :destroy]
  end

  # Pomocnicza metoda określająca role mające dostęp do zablokowanego wydarzenia
  access_control :access_to_prohibited?, :filter => false do
    allow :root
    allow :operator
    allow :owner,    :of => :calendar
  end

  # Używane w widoku, steruje dostępnością akcji
  access_control :helper => :allow_actions? do
    allow :root
    allow :operator
    allow :owner, :of => :calendar
  end

  private

  def load_data_show
    @calendar = Calendar.find(params[:id])
  end

  def load_data_new
    @calendar = Calendar.new
    @uploaded_file = UploadedFile.new
  end

  def load_data_update
    load_data_show
    @uploaded_file = UploadedFile.new
  end

  def check_access
    return if @calendar.can_show? || access_to_prohibited?
    raise Poema::Exception::NotFound
  end

  public

  # GET /calendars
  # GET /calendars.json
  def index
    @calendars = Calendar.list(Date.current, params[:page])
    respond_to do |format|
      format.html
      format.json { render :json => @calendars }
    end
  end

  # GET /calendars/1
  # GET /calendars/1.json
  def show
    @uploaded_files = UploadedFile.list @calendar
    @comments = Comment.list(@calendar, params[:comments_page])

    @calendar.view_counter_increment
    StatCounterObject.increment_counter 'view'

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @calendar }
    end
  end

  # GET /calendars/new
  # GET /calendars/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @calendar }
    end
  end

  # GET /calendars/1/edit
  def edit

  end

  # POST /calendars
  # POST /calendars.json
  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @calendar, :notice => 'Calendar was successfully created.' }
        format.json { render :json => @calendar, :status => :created, :location => @calendar }
      else
        format.html { render :action => "new" }
        format.json { render :json => @calendar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /calendars/1
  # PUT /calendars/1.json
  def update
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @calendar, :notice => 'Calendar was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @calendar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /calendars/1
  # DELETE /calendars/1.json
  def destroy
    @calendar.audit_params({:user => session_user, :ip => session_ip})
    @calendar.destroy

    respond_to do |format|
      format.html { redirect_to calendars_url }
      format.json { head :ok }
    end
  end

  private

  def create_or_update_record
    perform_in_transaction do
      new_record = @calendar.new_record?

      @calendar.owner = session_user if new_record

      @calendar.assign_attributes(params[:calendar])
      @calendar.should_geocode = true
      @calendar.audit_params({:user => session_user, :ip => session_ip})
      @calendar.save!

      unless (session_file = get_file_session).nil?
        @uploaded_file = session_user.owned_uploaded_files.new
        persist_destroy_file_session(session_file, @uploaded_file, @calendar, ContentCopyright.find(Poema::StaticId::get(:content_copyright, :permitted)), true)
      end

      StatCounterObject.increment_counter :calendar if new_record
    end
  end
end
