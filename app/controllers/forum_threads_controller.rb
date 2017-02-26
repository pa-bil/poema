class ForumThreadsController < ForumsCommonController
  access_control do
    deny  :banned,    :except => [:show]

    allow :root
    allow all,        :to => [:show]
    allow :user,      :to => [:new, :create]
    allow :owner,     :of => :forum_thread, :to => [:edit, :update]
  end

  # Używane w widoku, steruje dostępnością akcji
  access_control :helper => :allow_actions? do
    allow :root
    allow :owner, :of => :forum_thread
  end

  private

  def load_data
    @forum = Forum.find(params[:forum_id])
    if params[:id].nil?
      @forum_thread = @forum.forum_threads.new
    else
      @forum_thread = ForumThread.find(params[:id])
    end
  end

  public

  # GET /forum_threads/1
  # GET /forum_threads/1.json
  def show
    @forum_posts = @forum_thread.list_posts
    @forum_thread.view_counter_increment

    add_alert I18n.t(allow_reply_to?(@forum_thread, session_user) ? 'controller.forum_threads.thread_closed_owner' : 'controller.forum_threads.thread_closed') if @forum_thread.closed?
    add_alert I18n.t('controller.forum_threads.thread_banned') unless @forum_thread.can_show?

    StatCounterObject.increment_counter 'view'

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @forum_thread }
    end
  end

  # GET /forum_threads/new
  # GET /forum_threads/new.json
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @forum_thread }
    end
  end

  # GET /forum_threads/1/edit
  def edit
    add_notice I18n.t('controller.forum_threads.limited_editing')
  end

  # POST /forum_threads
  # POST /forum_threads.json
  def create
    respond_to do |format|
      if create_or_update_record :creator
        format.html { redirect_to forum_forum_thread_url(@forum, @forum_thread), :notice => I18n.t('controller.forum_threads.created') }
        format.json { render :json => @forum_thread, :status => :created, :location => @forum_thread }
      else
        format.html { render :action => "new" }
        format.json { render :json => @forum_thread.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /forum_threads/1
  # PUT /forum_threads/1.json
  def update
    respond_to do |format|
      if create_or_update_record(allow_reply_to?(@forum_thread, session_user) ? :updater : :nobody)
        format.html { redirect_to forum_forum_thread_url(@forum, @forum_thread), :notice => I18n.t('controller.forum_threads.updated') }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @forum_thread.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def create_or_update_record(as)
    perform_in_transaction do
      new_record = @forum_thread.new_record?
      was_closed = @forum_thread.closed?

      @forum_thread.assign_attributes(params[:forum_thread], :as => as)

      @forum_thread.owner = session_user if new_record

      @forum_thread.closed_by = session_user if (@forum_thread.closed? && !was_closed)
      @forum_thread.closed_by = nil if (!@forum_thread.closed? && was_closed)

      @forum_thread.audit_params({:user => session_user, :ip => session_ip})
      @forum_thread.save!

      StatCounterObject.increment_counter :forum_thread_or_post if new_record
    end
  end
end
