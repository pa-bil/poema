class ForumPostsController < ForumsCommonController
  # Filtrowanie dostępu do akcji kontrolera
  access_control do
    deny  :banned

    allow :root
    allow :user
  end

  private

  def load_data
    @forum = Forum.find(params[:forum_id])
    @forum_thread = ForumThread.find(params[:forum_thread_id])
    @forum_post = @forum_thread.forum_posts.new

    @forum_post_replied = ForumPost.find(params[:forum_post_id]) if !params[:forum_post_id].nil?

    raise Poema::Exception::AccessDenied unless allow_reply_to? @forum_thread, session_user
  end

  public

  # GET /forum_posts/new
  # GET /forum_posts/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @forum_posts }
    end
  end

  # POST /forum_posts
  # POST /forum_posts.json
  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to forum_forum_thread_url(@forum, @forum_thread), :notice =>  I18n.t('controller.forum_posts.created') }
        format.json { render :json => {:anchor => @forum_post.anchor}, :status => :created }
      else
        format.html { render :action => "new" }
        format.json { render :json => @forum_post.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def create_or_update_record
    perform_in_transaction do
      new_record = @forum_post.new_record?

      @forum_post.owner = session_user if new_record
      @forum_post.forum_post_id = @forum_post_replied.id if !@forum_post_replied.nil?
      @forum_post.assign_attributes(params[:forum_post])
      @forum_post.audit_params({:user => session_user, :ip => session_ip})
      @forum_post.save!

      StatCounterObject.increment_counter :forum_thread_or_post if new_record
    end
  end
end
