class RssController < ApplicationController
  def publications
    @publications = Publication.list_feed

    respond_to do |format|
      format.rss { render :layout => false }
    end
  end
end
