module FrontpageHelper
  def frontpage_render_feed_element(wrapper)
    grouping = wrapper
    element = wrapper.wrapped

    default_locals = {:avatar_size => 50, :avatar_main_size => 110, :grouping => grouping}
    cc_owner = Poema::StaticId::get(:content_copyright, :owner)

    case element
      when SpecialActionPublication
        render :partial => 'feed/special_action_publication', :locals => default_locals.merge({:publication => element.publication, :special_action => element.special_action, :special_action_publication => element})
      when ForumThread
        render :partial => 'feed/forum_thread', :locals => default_locals.merge({:t => element})
      when Comment
        # Komentarze do publikacji indywidualnych użytkowników
        if element.commentable.instance_of?(Publication) && element.commentable.content_copyright.id == cc_owner
            render :partial => 'feed/comment_publication_owned', :locals => default_locals.merge({:comment => element})
        else
          render :partial => 'feed/comment', :locals => default_locals.merge({:comment => element})
        end
      when Publication
        case element.content_copyright_id
          when cc_owner
            render :partial => 'feed/publication_owned', :locals => default_locals.merge({:publication => element})
          else
            render :partial => 'feed/publication_other', :locals => default_locals.merge({:publication => element})
        end
      when User
        render :partial => 'feed/user_signup', :locals => default_locals.merge({:user => element})
      when Calendar
        render :partial => 'feed/calendar', :locals => default_locals.merge({:calendar => element})
      else
        # Nothing, nie renderuję takiego elementu
    end
  end
end
