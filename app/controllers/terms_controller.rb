class TermsController < ApplicationController
  skip_before_filter :session_user_redirect_if_terms_not_current

  # Regulamin pokazujemy w procesie signupu, który idzie po SSLu
  skip_before_filter :https_to_http_redirect

  access_control do
    allow all
  end

  def index
    @current_version = TermsVersion.current!
    @terms = TermsVersion.order("introduced DESC")

    respond_to do |format|
      format.html { render :file => 'terms/index'}
      format.ajax { render :file => 'terms/index'}
    end
  end

  def show
    @current_version = TermsVersion.find(params[:id])
    @terms = TermsVersion.order("introduced DESC")
    
    respond_to do |format|
      format.html { render :file => 'terms/index'}
      format.ajax { render :file => 'terms/index'}
    end
  end
end
