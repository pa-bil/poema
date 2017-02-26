class UsersController < ApplicationController
  before_filter :load_data
  before_filter :check_access

  helper_method :privacy_allow_show_details?

  access_control do
    allow :root
    allow all
  end

  # Pomocnicza metoda określająca role mające dostęp do zablokowanej publikacji
  access_control :access_to_prohibited?, :filter => false do
    allow :root
    allow :owner,
          :of => :user
  end

  private

  def load_data
    @user = User.find(params[:id])
  end

  def check_access
    return if !@user.locked? || access_to_prohibited?
    raise Poema::Exception::NotFound
  end

  public

  # GET /users/1
  # GET /users/1.json
  def show
    add_alert I18n.t 'controller.users.locked' if @user.locked? # to się pokazuje wyłącznie dla rootów
    add_alert I18n.t 'controller.users.banned' if @user.banned?
    add_notice I18n.t 'controller.users.privacy' unless privacy_allow_show_details?(session_user, @user)

    @stat = @user.stat
    @comments = Comment.list @user, params[:comments_page]
    @comment_allowed = Comment.allowed_by_commentable? @user, session_user
    @commented = Comment.list_owned @user, 39

    @user.view_counter_increment

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user }
    end
  end

  def index_publications
    # blokowanie tego nie ma większego sensu - publikacje są widoczne publicznie
    # raise Poema::Exception::NotFound unless privacy_allow_show_details?(session_user, @user)

    @default_sort = Publication::SORT_BY_DATE
    @publications = Publication.list_by_owner(@user, params[:publications_page], params[:publications_sort], @default_sort)

    respond_to do |format|
      format.html
      format.json { render :json => @publications }
    end
  end

  # @param viewer User
  # @param owner User
  def privacy_allow_show_details?(viewer, owner)
    viewer && ((owner.visible? && !owner.banned?) && !UserBlacklist.on_blacklist?(owner, viewer) || viewer.id == owner.id || viewer.has_role?(:root))
  end
end
