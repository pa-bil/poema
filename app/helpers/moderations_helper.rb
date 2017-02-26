module ModerationsHelper
  def moderateable_path(moderation)
   moderateable = moderation.moderateable
   case moderateable
      when Comment
        comment_context = moderateable.commentable
        case comment_context
          when Container
            container_path(comment_context)
          when Publication
            publication_path(comment_context)
          when User
            user_path(comment_context)
          when Calendar
            calendar_path(comment_context)
          else
            raise "Unknown context"
        end
      when User
        user_path(moderateable)
      when ForumThread
        forum_forum_thread_path(moderateable.forum, moderateable)
      when ForumPost
        forum_forum_thread_path(moderateable.forum_thread.forum, moderateable.forum_thread)
      else
        raise "Unknown context"
    end
  end

  def new_moderation_path(moderateable,  moderateable_context = nil)
    case moderateable
      when Comment
        # moderateable: Comment, moderateable_context: Publication|Container|User
        case moderateable_context
          when Container
            new_container_comment_moderations_path(moderateable_context, moderateable)
          when Publication
            new_publication_comment_moderations_path(moderateable_context, moderateable)
          when User
            new_user_comment_moderations_path(moderateable_context, moderateable)
          when Calendar
            new_calendar_comment_moderations_path(moderateable_context, moderateable)
          else
            raise "Unknown context"
        end
      when User
        new_user_moderations_path(moderateable)
      when ForumThread
        new_forum_forum_thread_moderations_path(moderateable.forum, moderateable)
      when ForumPost
        new_forum_forum_thread_forum_post_moderations_path(moderateable.forum_thread.forum, moderateable.forum_thread, moderateable)
      else
        raise "Unknown context"
    end
  end

  def moderations_path(moderateable, moderateable_context = nil)
    case moderateable
      when Comment
        case moderateable_context
          when Container
            container_comment_moderations_path(moderateable_context, moderateable)
          when Publication
            publication_comment_moderations_path(moderateable_context, moderateable)
          when User
            user_comment_moderations_path(moderateable_context, moderateable)
          when Calendar
            calendar_comment_moderations_path(moderateable_context, moderateable)
          else
            raise "Unkonwn moderateable_context"
        end
      when User
        user_moderations_path(moderateable)
      when ForumThread
        forum_forum_thread_moderations_path(moderateable.forum, moderateable)
      when ForumPost
        forum_forum_thread_forum_post_moderations_path(moderateable.forum_thread.forum, moderateable.forum_thread, moderateable)
      else
        raise "Unknown context"
    end
  end
end
