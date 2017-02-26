class Admin::UsersController < User::ProfilesController
  before_filter :load_data

  access_control do
    allow :root
  end

  private

  def load_data
    if params[:id]
      @user = User.with_deleted.find(params[:id])
      @auth = @user.auth
    end
  end

  public

  def index
    @user_search = AdminUserSearchForm.new
  end

  def search
    @user_search = AdminUserSearchForm.new(params[:admin_user_search_form])

    if @user_search.valid?
      @users = User.search_admin(@user_search.q.strip, params[:users_page])
      respond_to do |format|
        format.html
        format.json { render :json => @users }
      end
    else
      render :action => :index
    end
  end

  def show
    super
    @user_update_log = UserUpdateLog.list_by_user(@user)
    @moderations = Moderation.list_by_user(@user)
  end

  def update
    if update_profile_or_auth
      redirect_to admin_user_path(@user), :notice => "Updated user's account"
    else
      render :action => "edit"
    end
  end

  # Proces usuwania konta użytkownika od strony administracyjnej wygląda nieco inaczej, dla tego nie
  # wykorzystuję metod z klasy potomnej
  def delete
    @profile_remove = AdminUserRemoveForm.new
  end

  def destroy
    if destroy_record_admin_remove
      redirect_to admin_users_path, :notice =>  "Deleted user's account"
    else
      render :action => "delete"
    end
  end

  protected

  def destroy_record_admin_remove
    @profile_remove = AdminUserRemoveForm.new(params[:admin_user_remove_form])
    @profile_remove.user = @user

    if @profile_remove.valid?
      perform_in_transaction do
        # Potrzebuję kopii obiektu do wysłanego na końcu maila
        u = @user.clone

        Publication.destroy_all_owned_by(@user) if @profile_remove.remove_pubs_owned?
        Container.destroy_all_empty_owned_by(@user)

        @auth.audit_params({:user => session_user, :ip => request.remote_ip, :description => "Removed user's account, reason: #{@profile_remove.reason}"})
        @auth.destroy

        if @profile_remove.remove_personal_data?
          # Dodatkowy audyt w kontekście użytkownika, mówiący, że usunęliśmy dane osobowe użytkownika
          @user.audit!({:user => session_user, :ip => request.remote_ip, :event_type => Audit::EVENT_DESTROY, :level => Audit::LEVEL_INFO, :description => "Removed all user's personal data, reason: #{@profile_remove.reason}"})
          UserUpdateLog.destroy_all_owned_by(@user)
        end

        UserMailer.account_administrative_destroy(u)
      end
    else
      false
    end
  end

  def update_auth_audit_description
    'User\'s password has been changed by administrator'
  end
end
