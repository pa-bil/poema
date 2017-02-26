class UploadedFilesController < ApplicationController
  before_filter :load_data
  before_filter :check_access

  # To jest kontroler administracyjny, wjazd tutaj ma tylko właściciel kontekstu, lub właściciel
  # plików
  access_control do
    deny  :banned,     :to => [:new, :create, :edit, :update]

    allow :root
    allow :operator
    allow :owner,      :of => :uploadable, :to => [:index, :new, :create]
    allow :owner,      :of => :uploaded_file, :to => [:delete, :destroy]
  end

  access_control :access_to_prohibited?, :filter => false do
    allow :root
    allow :operator
    allow :owner, :of => :uploadable
    allow :owner, :of => :uploaded_file
  end
  
  private

  def load_data
    @uploadable = params[:context].constantize.find(params["#{params[:context].downcase}_id"])
    if params[:id]
      @uploaded_file = UploadedFile.find(params[:id])
    else
      @uploaded_file = @uploadable.uploaded_files.new
    end
  end

  def check_access
    return if @uploadable.can_show? || access_to_prohibited?
    raise Poema::Exception::NotFound
  end

  public

  # GET /uploaded_files
  # GET /uploaded_files.json
  def index
    @uploaded_files = UploadedFile.list_all @uploadable
    respond_to do |format|
      format.html
      format.json { render :json => @uploaded_files }
    end
  end
  
  # GET /uploaded_files/new
  # GET /uploaded_files/new.json
  def new
    save_redirect_from_referer_url true
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @uploaded_file }
    end
  end

  # POST /uploaded_files
  # POST /uploaded_files.json
  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to get_truncate_redirect, :notice => I18n.t('controller.uploaded_files.created') }
        format.json { render :json => @uploaded_file, :status => :created, :location => @uploaded_file }
      else
        format.html { render :action => "new" }
        format.json { render :json => @uploaded_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete
    respond_to do |format|
      format.html
      format.ajax { render 'delete.ajax' }
      format.json { render :json => @uploaded_file }
    end
  end

  # DELETE /uploaded_files/1
  # DELETE /uploaded_files/1.json
  def destroy
    destroy_record
    respond_to do |format|
      format.html { redirect_to :back, :notice => I18n.t('controller.uploaded_files.destroyed')  }
      format.json { head :ok }
    end
  end

  private

  def destroy_record
    perform_in_transaction do
      if @uploadable.avatar? && @uploadable.avatar.id == @uploaded_file.id
        @uploadable.avatar = nil
        @uploadable.save!
      end

      @uploaded_file.audit_params({:user => session_user, :ip => session_ip})
      @uploaded_file.destroy
    end
  end

  def create_or_update_record
    perform_in_transaction do
      new_record = @uploaded_file.new_record?

      @uploaded_file.owner = session_user if new_record

      @uploaded_file.assign_attributes(params[:uploaded_file])
      @uploaded_file.audit_params({:user => session_user, :ip => session_ip})
      @uploaded_file.save!

      @uploadable.uploaded_files << @uploaded_file

      if @uploaded_file.is_avatar? && !@uploaded_file.content_copyright.prohibit_exposition?
        @uploadable.avatar = @uploaded_file
        @uploadable.save!
      end

      StatCounterObject.increment_counter :uploaded_file if new_record
    end
  end
end
