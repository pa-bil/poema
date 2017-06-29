class FrontpageController < ApplicationController
  access_control do
    allow all
  end

  def index
  end

  def feed
    response.headers["Cache-Control"] = "public, max-age=120"
    @feed = aggregate_static_feed
  end

  private

  def aggregate_static_feed
    [].
      concat(ForumThread.list_recent).
      concat(Publication.list_feed(50)).
      concat(Comment.list_feed(30)).
      concat(User.list_recent).
      concat(Calendar.list_recent.concat(Calendar.list_current).uniq).
      concat(SpecialActionPublication.list_feed).
      sort {|a, b| b.sort_value <=> a.sort_value}
  end
end
