class ForumsCommonController < ApplicationController
  helper_method :allow_reply_to?

  before_filter :load_data
  before_filter :check_access

  access_control :access_to_prohibited?, :filter => false do
    allow :root
    allow :operator
  end

  protected

  def check_access
    return if access_to_prohibited?

    if @forum_thread
      return if @forum_thread.can_show?
      raise Poema::Exception::NotFound
    else
      return if @forum.can_show?
      raise Poema::Exception::NotFound
    end
  end

  # Helper: używany w widokach, ale również w kontrolerach, używając logiki z obiektów ForumThread lub ForumPost
  # mówi, czy można na dany element odpowiedzieć
  def allow_reply_to?(forum_thread_or_post, user)
    forum_thread_or_post.allow_reply? user
  end
end
