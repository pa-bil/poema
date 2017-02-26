class UserBlacklistsController < ApplicationController
  before_filter :load_data

  before_filter :load_data_new, :only => [:new, :create]
  before_filter :load_data_del, :only => [:delete, :destroy]

  access_control do
    allow :user, :to => [:new, :create, :delete, :destroy]
  end

  private

  def load_data
    return if session_user.nil?    
    @user = User.find(session_user.id)
    @user_blacklisted = User.find(params[:user_id])
  end

  def load_data_new
    return if @user.nil?
    @user_blacklist = @user.owned_user_blacklists.new
  end

  def load_data_del
    return if @user.nil?
    @user_blacklist = @user.owned_user_blacklists.where(:blacklisted_user_id => params[:user_id]).first!
  end

  public

  def new
    save_redirect_from_referer_url true
    respond_to do |format|
      format.html # new.html.erb
      format.ajax # new.ajax.erb
      format.json { render :json => @user_blacklist }
    end
  end

  def create
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to get_truncate_redirect, :notice => I18n.t('controller.user_blacklists.create') }
        format.json { render :json => @user_blacklist, :status => :created, :location => @user_blacklist }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user_blacklist.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if destroy_record
        format.html { redirect_to user_profile_path, :notice =>  I18n.t('controller.user_blacklists.destroyed') }
        format.json { head :ok }
      else
        format.html { render :action => "delete" }
        format.json { render :json => @user_blacklist.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def destroy_record
    perform_in_transaction do
      @user_blacklist.audit_params({:user => session_user, :ip => session_ip})
      @user_blacklist.destroy
    end
  end

  def create_or_update_record
    perform_in_transaction do
      @user_blacklist.assign_attributes(params[:user_blacklist])
      @user_blacklist.blacklisted = @user_blacklisted
      @user_blacklist.audit_params({:user => session_user, :ip => session_ip})
      @user_blacklist.save!

      StatCounterObject.increment_counter :user_blacklist_add
    end
  end
end
