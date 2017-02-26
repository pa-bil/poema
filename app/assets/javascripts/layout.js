/*
 * inicjalizacja elementów layoutu, ten kod jest wykonywany na każdej
 * stronie, powinien wykonywać akcje na wspólnych elementach layoutu
 */

Poema.Register(Poema.Layout = {});

Poema.Layout.Name = "Layout";
Poema.Layout.Init = function() {  return true; };
Poema.Layout.Exec = function()
{
  Poema.Layout.TopMenu();
  Poema.Layout.AdminLinks();
  Poema.Layout.AnimatedBox();
  Poema.Layout.Popups();
  Poema.Layout.Tooltips();
  Poema.Layout.Card.AttachAll();
  Poema.Ui.Linkify.Init($('body'));
  Poema.Google.GA.Init();
};

// inicjalizacja wszystkich mechanizmów górnego menu
Poema.Layout.TopMenu = function() {
  var mc = $('#main-top-bar-float-container');
  if (mc.length > 0) {
    var mc_opacity = mc.css('opacity');
    var mc_filter = mc.css('filter');

    mc.bind('mouseover', function() {
      mc.css('opacity', '0.95').css('filter', 'alpha(opacity=95)');
    });
    mc.bind('mouseout', function() {
      mc.css('opacity', mc_opacity).css('filter', mc_filter);
    });
  }
  $('#main-top-bar-tools-search-button').click(function(e) {
    e.preventDefault();
    $('#main-top-bar-tools-search-form').trigger('submit');
  });
};

Poema.Layout.AdminLinks = function() {
  $('.admin_links').each(function() { $(this).css({display: 'none'}) });

  var tools_count_container = $('#main-top-bar-tools-counter');
  if (tools_count_container.length > 0) {
    var tools_count = 0;
    $('.admin_links').find('li').each(function() {
      tools_count = tools_count + 1;
    });
    tools_count_container.html(tools_count);
  }

  // Animujemy cyferkę
  if (tools_count > 0) {
    var animate_func = function() {
      tools_count_container.effect('shake', {'direction': 'down', 'distance': 6, 'times': 2});
    }
    setTimeout(animate_func, 1000);
  }

  $('#context-menu-button').bind('click', function(e) {
    e.preventDefault();
    var container = Poema.Ui.Popup.Container();
    var options = Poema.Ui.Popup.Options({width: 370});
    container.html('');
    container.attr('title', "Akcje dostępne dla tej strony").unbind().bind("dialogopen", function() {
      var html = '<ul id="popup-actions-menu">';
      var al = $('.admin_links');
      if (al.length > 0) {
        $('.admin_links').find('li').each(function() {
          html = html + '<li>' +  $(this).html() + '</li>';
        });
      }
      html = html + '</ul>';
      container.html(html);
    }).dialog(options).dialog("open");
  });

  $('#tools_counter').css({display: 'block'});
};

Poema.Layout.AnimatedBox = function() {
  $('body').find('div.poema_animated_box').each(function(){
    Poema.Ui.AnimatedBox.Animate($(this))
  });
};

Poema.Layout.Popups = function() {
  var options = Poema.Ui.Popup.Options({width: 450});
  $('body').find('.poema_popup').each(function() {
    var url = $(this).attr('href');
    if (!url) {
      return;
    }
    Poema.Log('Ui.Popup.Init: ' + url);
    $(this).bind('click', function(e) {
      e.preventDefault();
      var container = Poema.Ui.Popup.Container();
      container.attr('title', $(this).attr('title')).unbind().bind("dialogopen", function() {
        Poema.Ajax.Load(url, container);
      }).dialog(options).dialog("open");
    });
  });
};

Poema.Layout.Tooltips = function () {
  $(".poema_tooltip").tooltip(Poema.Ui.Tooltip.OptionsUp());
  $(".poema_help").tooltip(Poema.Ui.Tooltip.OptionsUp());
  $(".poema_tooltip_down").tooltip(Poema.Ui.Tooltip.OptionsDown());
};

Poema.Layout.Card = {};
Poema.Layout.Card.AttachAll = function() {
  $('.card').each(function() {
    // Wyszykuję w każdej z wizytówek blok .extended_info który ma jakieś elementy w środku
    // Dopiero wtedy binduję zdarzenia
    var extended = $(this).find('.extended_info');
    if (extended.length > 0 && extended.children().length > 0) {
      var bar = $(this).find('.bar');
      if (bar.length > 0) {
        $(this).bind('mouseover', function() {
          extended.removeClass('hidden');
          bar.removeClass('card_bar_border_light').addClass('card_bar_border_dark');
        });
        $(this).bind('mouseout', function() {
          extended.addClass('hidden');
          bar.removeClass('card_bar_border_dark').addClass('card_bar_border_light');
        });
      }
    }
  });
};