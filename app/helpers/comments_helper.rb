# encoding: utf-8
module CommentsHelper
  def new_comment_path(context)
    case context
      when Container
        new_container_comment_path(context)
      when Publication
        new_publication_comment_path(context)
      when User
        new_user_comment_path(context)
      when Calendar
        new_calendar_comment_path(context)
      else
        raise "Unknown context"
    end
  end

  def comment_commentable_to_human(comment)
    c = comment.commentable
    case c
      when Container
        "Komentarz do kontenera #{c.title}"
      when Publication
        "Komentarz do publikacji #{c.title}"
      when User
        "Komentarz do konta użytkownika #{c.name}"
      when Calendar
        "Komentarz do wydarzenia #{c.title}"
      else
        "Komentarz"
    end
  end
end
