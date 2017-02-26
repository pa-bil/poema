Poema.Comments = {};

Poema.Comments.Init = function() {
  Poema.Comments.Popup();
};

Poema.Comments.Load = function(into) {
  Poema.Ajax.Load(Poema.Url.Current.Get() + '/komentarz', into, Poema.Comments.Init)
};

Poema.Comments.Popup = function() {
  $('.comment_add_button').each(function() {
    var url = $(this).attr('href');
    var click = function(e)
    {
     e.preventDefault();
     var options = Poema.Ui.Popup.Options({width: 450});
     var container = Poema.Ui.Popup.Container();
     container.attr('title', 'Dodaj komentarz').addClass('comments_form_popup').unbind().bind("dialogopen", function() {
       Poema.Ajax.Load(url, container, function() {
         Poema.Json.Form($("#new_comment"), 'comment', function() {
           container.dialog('close');
           Poema.Comments.Load($('#divCommentsList'));
         });
       });
     }).dialog(options).dialog("open");
    };
    $(this).bind('click', click);
  });
};

Poema.Comments.Button = function() {
  $('.comments_list').each(function() {
    var list = $(this);
    var button = list.find('.comment_add_button').first();
    if (button.length > 0) {
      if ($('.comment').length > 0) {
        button.addClass('hidden');
      }
      list.find('.comment').each(function() {
        $(this).mouseenter(function() {
          var t = $(this).position().top;
          var l = ($(this).position().left + $(this).width() - 64);
          button.fadeOut('fast', function() {
            $(this).css({position: 'absolute', left:l, top: t});
            $(this).fadeIn('slow');
          });
        });
      });
    }
  });
};

