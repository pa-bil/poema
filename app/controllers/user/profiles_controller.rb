class User::ProfilesController < ApplicationController
  include Poema::FileUploadSession
  
  before_filter :load_data

  access_control do
    deny anonymous
    allow :owner, :of => :user
  end

  private

  def load_data
    if session_user?
      @user = User.find(session_user.id)
      @auth = @user.auth
      @uploaded_file = UploadedFile.new
    end
  end

  # Optymalizacja: te listy mogą być duże, nie ładuję ich przy akcjach nie wymagających wyświetlenia treści
  def load_show_data
    @publications = Publication.list_owned @user
    @containers = Container.list_owned @user
    @blacklists = UserBlacklist.list_by_owner @user
  end

  public

  def show
    load_show_data
    StatCounterObject.increment_counter 'view'
  end

  def update
    respond_to do |format|
      if update_profile_or_auth
        format.html { redirect_to user_profile_url, :notice => I18n.t('controller.profiles.update') }
        format.json { head :ok }
      else
        load_show_data
        format.html { render :action => "show" }
        format.json { render :json => [].concat(@user.errors).concat(@auth.errors), :status => :unprocessable_entity }
      end
    end
  end

  def delete
    @profile_remove = UserSelfRemoveForm.new
    respond_to do |format|
      format.html
      format.ajax
      format.json { render :json => @user }
    end
  end

  def destroy
    respond_to do |format|
      if destroy_record_self_remove
        format.html { redirect_to root_url, :notice =>  I18n.t('controller.profiles.destroy') }
        format.json { head :ok }
      else
        format.html { render :action => "delete" }
        format.ajax { render :action => "delete" }
        format.json { render :json => {}, :status => :unprocessable_entity }
      end
    end
  end

  protected

  # Usunięcie użytkownika, co robimy?
  # - trzeba usunąć Auth - to pociągnie zależności
  # - trzeba ubić sesję usera
  # - trzeba wysłać mu list
  # - wyświetlić exit pool
  def destroy_record_self_remove
    @profile_remove = UserSelfRemoveForm.new(params[:user_self_remove_form])
    @profile_remove.user = @user
    @profile_remove.auth = @auth

    if @profile_remove.valid?
      perform_in_transaction do
        # Potrzebuję kopii obiektu do wysłanego na końcu maila
        u = @user.clone

        # Usuwamy wszystkie publikacje, których jest właścicielem, i które zostały oznaczone jako te, do których ma prawa autorskie
        Publication.destroy_all_owned_by(@user) if @profile_remove.remove_pubs_owned?

        # Usuwamy wszystkie kontenery, których jest właścicielem, a które są puste
        Container.destroy_all_empty_owned_by(@user)

        @auth.audit_params({:user => session_user, :ip => request.remote_ip, :description => "User requested to self-remove his account"})
        @auth.destroy

        reset_session

        UserMailer.account_self_destroy(u)
      end
    else
      false
    end
  end

  def update_profile_or_auth
    perform_in_transaction do
      unless params[:user].nil?
        @user.assign_attributes(params[:user])
        @user.audit_params({:user => session_user, :ip => request.remote_ip})
        @user.save!

        unless (session_file = get_file_session).nil?
          @uploaded_file = @user.owned_uploaded_files.new
          persist_destroy_file_session(session_file, @uploaded_file, @user, ContentCopyright.find(Poema::StaticId::get(:content_copyright, :dontknow)), true)
        end
      end

      unless params[:auth].nil?
        @auth.assign_attributes(params[:auth])
        @auth.audit_params({:user => session_user, :ip => request.remote_ip, :description => update_auth_audit_description})
        @auth.save!
      end
    end
  end

  def update_auth_audit_description
    'User changed password'
  end
end
