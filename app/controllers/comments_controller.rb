class CommentsController < ApplicationController
  before_filter :load_data
  before_filter :check_access

  access_control do
    deny  :banned,  :except => [:index]

    allow :root
    allow all       # Dodatkowe uprawnienia sterowane poprzez allow_comments sprawdzone zostaną w check_access
  end

  private

  def load_data
    @commentable = params[:context].constantize.find(params["#{params[:context].to_underscore}_id"])
    if params[:id].nil?
      @comment = @commentable.comments.new
    else
      @comment = Comment.find(params[:id])
    end
  end

  def check_access
    raise Poema::Exception::AccessDenied unless @commentable.can_show?  # nie sprawdzam tutaj żadnych dodatkowych warunków
                                                                        # na dostęp, komentarz nie ma racji bytu przy niedostępnym kontekście

    case Comment.check_policy_for_commentable(@commentable, session_user)
      when Comment::POLICY_DENY
        raise Poema::Exception::AccessDenied
      when Comment::POLICY_REQUIRE_AUTH
        raise Poema::Exception::AuthRequired
      when Comment::POLICY_ALLOW
        # Tu jest ok
      else
        raise Poema::Exception::NotFound
    end
  end

  public

  # GET /comments
  # GET /comments.json
  def index
    @comments = Comment.list @commentable
    @comment_allowed = Comment.allowed_by_commentable? @commentable, session_user

    respond_to do |format|
      format.html
      format.json { render :json => @comments }
    end
  end

  # GET /comments/new
  # GET /comments/new.json
  def new
    respond_to do |format|
      format.html
      format.ajax
      format.json { render :json => @comment }
    end
  end

  # POST /comments
  # POST /comments.json
  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to @commentable, :notice => 'Comment was successfully created.' }
        format.json { render :json => @comment, :status => :created }
      else
        format.html { render :action => "new" }
        format.json { render :json => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def create_or_update_record
    perform_in_transaction do
      new_record = @comment.new_record?

      @comment.owner = session_user if new_record

      @comment.assign_attributes(params[:comment], :as => session_user_assign_attributes_as)
      @comment.audit_params({:ip => session_ip, :user => session_user})
      @comment.save!
      @commentable.comments << @comment

      StatCounterObject.increment_counter :comment if new_record

      UserMailer.new_comment_arrived(@commentable, @comment)
    end
  end
end
