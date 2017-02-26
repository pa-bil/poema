class TermsAcceptController < ApplicationController
  skip_before_filter :session_user_redirect_if_terms_not_current

  before_filter :load_data
  before_filter :check_access

  access_control do
    deny anonymous
    allow logged_in
  end

  private

  def load_data
    @terms_version = TermsVersion.find(params[:term_id])
    @user = User.find(session_user.id) if session_user?
  end

  def check_access
    raise Poema::Exception::NotFound if session_user? && session_user.terms_version.current?
  end

  public

  def new
  end

  def update    
    respond_to do |format|
      if create_or_update_record
        format.html { redirect_to get_truncate_redirect, :notice => I18n.t('controller.termsaccept.updated') }
        format.json { head :ok }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def create_or_update_record
    perform_in_transaction do
      @user.assign_attributes(params[:user])
      @user.save!

      tal = @user.terms_accept_logs.build({:accepted => true, :terms_version => @terms_version})
      tal.audit_params({:user => session_user, :ip => session_ip, :description => "User accepted terms, version #{@terms_version.id}"})
      tal.save!

      @user.terms_accept_logs << tal
    end
  end
end
