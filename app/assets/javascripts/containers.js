Poema.Register(Poema.Containers = {});

Poema.Containers.Name = "Containers";
Poema.Containers.Init = function() {  return ($('#divContainers').length > 0); };
Poema.Containers.Exec = function() {
  Poema.Scroll.UsingAnchor(function(target) {
    target.effect('highlight', 3000);
  });
  Poema.Comments.Init();
  Poema.Ui.Gallery();

  var f = $('#container_granted_container_creator_role_id');
  if (f.length) {
    Poema.Autocomplete.Roles(f);
  }
  var g = $('#container_granted_publication_creator_role_id');
  if (g.length) {
    Poema.Autocomplete.Roles(g);
  }
};

Poema.Containers.Picker = {};

Poema.Containers.Picker.Init = function(picker_url, on_cp_pick) {
  var options = Poema.Ui.Popup.Options({width: 500});
  var container = Poema.Ui.Popup.Container();

  container.attr('title', 'Wybierz kontener').unbind().bind("dialogopen", function() {
    Poema.Ajax.Load(picker_url, container, function() {
      Poema.Containers.Picker.Load(on_cp_pick);
    });
  }).dialog(options).dialog("open");
};

Poema.Containers.Picker.Load = function(on_cp_pick) {
  var cpl = $('#containers-picker-list'), cpm = $('#containers-picker-more'), container = Poema.Ui.Popup.Container();
  var cnt = 0, limit = 50;

  var func_limit_decision = function(c, elem) {
    if (c <= limit) {
      elem.removeClass('hidden');
    }
    else {
      elem.addClass('hidden');
    }
  };

  $('#containers-picker-path').find('a').each(function() {
    // Tu binduję operacje przeładowania zawartości popupa po kliknięciu w element ścieżki
    $(this).bind('click', function(e) {
      e.preventDefault();
      Poema.Ajax.Load($(this).attr('href'), container, function() {
        Poema.Containers.Picker.Load(on_cp_pick);
      });
    });
  });
  cpl.find('li').each(function() {
    // Dodaję do każdego z linków do wyboru kolejnego kontenera zdarzenie przeładowania zawartości popupa z wybranym URLem
    // a także odkrywam n pierwszych elementów (domyślnie wszystkie li są hidden)
    func_limit_decision((cnt = cnt + 1), $(this));
    var a = $(this).find('a').first();
    a.bind('click', function(e) {
      e.preventDefault();
      Poema.Ajax.Load(a.attr('href'), container, function() {
        Poema.Containers.Picker.Load(on_cp_pick);
      });
    });
    if (cnt > limit) {
      cpm.html('...i jeszcze ' + (cnt - limit) + " więcej, użyj wyszukiwarki").removeClass('hidden');
    }
    else {
      cpm.addClass('hidden');
    }
  });
  $('#containers-picker-container-find').bind('keyup', function() {
    // Wyszukiwanie kontenerów na liście
    var search = $(this).val().toLowerCase(), cnt = 0;
    cpl.find('li').each(function() {
      var a = $(this).find('a').first();
      var title = a.html().toLowerCase();
      if (search == '') {
        func_limit_decision((cnt = cnt + 1), $(this));
      }
      else {
        if (title.indexOf(search) !== -1) {
          func_limit_decision((cnt = cnt + 1), $(this));
        }
        else {
          $(this).addClass('hidden');
        }
      }
      if (cnt > limit) {
        cpm.html('...i jeszcze ' + (cnt - limit) + " więcej, użyj wyszukiwarki").removeClass('hidden');
      }
      else {
        cpm.addClass('hidden');
      }
    });
  });
  $('#containers-picker-submit').bind('click', function() {
    // Zdarzenie kliknięcia w przycisk 'wybierz'
    on_cp_pick($('#containers-picker-container-id').val(), $('#containers-picker-container-title').val(), $('#containers-picker-container-link').val());
    container.dialog('close');
  });
};