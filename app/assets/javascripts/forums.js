Poema.Register(Poema.Forums = {});

Poema.Forums.Name = "Forums";
Poema.Forums.Init = function() {  return ($('#divForums').length > 0); };

Poema.Forums.Exec = function() {
  Poema.Scroll.UsingAnchor(function(target) {
    target.effect('highlight', 3000);
  });

  // Jako, że ukrywamy JSem panel z linkami administracyjnymi, dodatkowy button, który pojawia się zamiast panelu
  // domyślnie via CSS jest niewidoczny, i powinien zostać odkryty JSem
  $('.forum_thread_new_button').removeClass('hidden');

  // Pływający przycisk odpowiedzi na stronie wątku (lista odpowiedzi)
  $('.forum_thread').find('.top').each(function() {
    Poema.Forums.ReplyButton($(this), true)
  });
  $('.forum_thread').find('.list').find('.item').each(function() {
    Poema.Forums.ReplyButton($(this));
  });
};

Poema.Forums.ReplyButton = function(area, is_thread) {
  if (area.length < 1) {
    return;
  }
  var reply_link = area.find('a.reply');
  if (reply_link.length > 0) {
    reply_link.addClass('hidden');

    var button = $('#forum_post_reply_tooltip');
    var container = Poema.Ui.Popup.Container();

    var func_click =  function(e) {
      e.preventDefault();
      container.attr('title', "Nowa odpowiedź").addClass('forum_posts_form_popup').unbind().bind("dialogopen", function() {
        var on_load = function() {
          Poema.Json.Form($("#new_forum_post"), 'forum_post', function(data) {
            container.dialog('close');
            Poema.Url.GoTo(Poema.Url.Current.Path() + '#' + data.anchor);
          }, function(e) {
            e.preventDefault();
            container.dialog('close');
          });
        };
        Poema.Ajax.Load(reply_link.attr('href'), Poema.Ui.Popup.Container(), on_load);
      }).dialog(Poema.Ui.Popup.Options({width: 450})).dialog("open");
    };

    area.mouseenter(function() {
      var id = $(this).attr('id');
      var t, l;
      if (is_thread) {
        t = $(this).position().top + 160 - 60;
        l = $(this).position().left + 160 - 60;
      }
      else {
        t = $(this).position().top + 160 - 60;
        l = ($(this).position().left + $(this).width()) - 60;
      }
      if (button.attr('data-selected-id') != id) {
        button.attr('data-selected-id', id).removeClass('hidden').fadeOut('fast', function() {
          $(this).css({position: 'absolute', left:l, top: t}).unbind().bind('click', func_click).fadeIn('slow');
        });
      }
    });
  }
};
