module ForumPostsHelper
  def forum_post_new_path(f ,t, p = nil)
    r = ''
    r << new_forum_forum_thread_forum_post_path(f, t)
    r << "?forum_post_id=#{p.id}" unless p.nil?
    r
  end
end
