class StaticPageController < ApplicationController
  access_control do
    allow all
  end

  def index
    raise Poema::Exception::NotFound
  end

  def robots
    f = Rails.root + "config/environments/#{Rails.env}.robots.txt"    
    
    raise Poema::Exception::NotFound unless File.exists?(f)
    render :text => File.read(f), :layout => false, :content_type => "text/plain"
  end

  def show
    raise Poema::Exception::NotFound unless File.exists?(Rails.root.join("app", "views", params[:controller], "#{params[:page]}.html.erb"))

    respond_to do |format|
       format.html { render :file => 'static_page/' + params[:page]}
     end
  end
end
