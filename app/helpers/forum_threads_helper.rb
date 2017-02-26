module ForumThreadsHelper
  # Ta metoda robi magię, kiedy przy budowaniu linku do wątku forum używany jest sam wątek, używane w akcjach których
  # jedynym kontekstem jest pojedynczy obiekt, eg. moderacja
  def forum_thread_path(forum_thread)
    forum_forum_thread_path(forum_thread.forum, forum_thread)
  end
end
