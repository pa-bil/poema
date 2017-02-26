class ModerationsController < ApplicationController
  before_filter :load_data

  access_control do
    # Tu nie ma roota, root nie musi być moderatorem
    allow :moderator
  end

  private

  def load_data
    @moderateable = params[:context].constantize.find(params["#{params[:context].to_underscore}_id"])
    case params[:context]
      when Comment.name
        # Komentarz jest kontekstem pierwotnym (moderateable), jest jeszcze kontekst samego komentarza (kontener, publikacja)
        # który potrzebny jest do poprawnego wygenerowania linków
        @moderateable_context = @moderateable.commentable
      when ForumPost.name
        @moderateable_context = @moderateable.forum_thread
      else
        @moderateable_context = @moderateable
    end
  end

  public

  # GET /moderations/new
  # GET /moderations/new.json
  def new
    save_redirect_from_referer_url true
    @moderation = @moderateable.moderations.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @moderation }
    end
  end

  # POST /moderations
  # POST /moderations.json
  def create
    @moderation = @moderateable.moderations.new
    respond_to do |format|
      if perform_moderation
        format.html { redirect_to get_truncate_redirect, :notice => I18n.t('controller.moderations.created') }
        format.json { render :json => @moderation, :status => :created, :location => @moderateable_context }
      else
        format.html { render :action => "new" }
        format.json { render :json => @moderation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete
    respond_to do |format|
      format.html
      format.ajax
      format.json { render :json => @moderateable.moderations }
    end
  end

  # DELETE /moderations/1
  # DELETE /moderations/1.json
  def destroy
    respond_to do |format|
      if perform_moderation_revert
        format.html { redirect_to :back }
        format.json { head :ok }
      else
        format.html { render :action => "delete" }
        format.json { render :json => @moderation.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def perform_moderation
    perform_in_transaction do
      @moderation.assign_attributes(params[:moderation])
      @moderation.moderator = session_user
      @moderation.save!

      @moderateable.toggle! :banned unless (already_banned = @moderateable.banned?)

      if @moderateable.instance_of?(User)
        unless already_banned
          StatCounterObject.increment_counter :ban
          Role.list_generic.each{|role|
            @moderateable.has_no_role! role.name if @moderateable.has_role? role.name
          }
          InternalMailer.ban_created(@moderation).deliver
          UserMailer.ban_created(@moderation).deliver
        end
      else
        StatCounterObject.increment_counter :moderation
        InternalMailer.moderation_created(@moderation, @moderateable_context).deliver unless already_banned
      end
    end
  end

  def perform_moderation_revert
    perform_in_transaction do
      mods = @moderateable.moderations
      mods.each {|mod|
        mod.update_attribute(:active, false)
      }
      @moderateable.toggle!(:banned) if @moderateable.banned?

      if @moderateable.instance_of?(User)
        @moderateable.assign_default_roles

        InternalMailer.ban_reverted(session_user, @moderateable).deliver
        UserMailer.ban_reverted(@moderateable).deliver
      else
        InternalMailer.moderation_reverted(session_user, @moderateable, @moderateable_context).deliver
      end
    end
  end
end
