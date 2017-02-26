Poema.Autocomplete = {};
Poema.Autocomplete.Add = function(field, endpoint, row_parser, result_parser, on_change) {
  if (!result_parser) {
    result_parser = row_parser;
  }
  if (field.length > 0) {
    Poema.Log("Autocomplete.Add: " + field.attr('id'));
    field.autocomplete(endpoint, {
      onChange: on_change,
      scroll: false,
      dataType: 'json',
      parse: function(data) {
        return $.map(data.results, function(row) {
          return {
            data:   row,
            value:  row_parser(row),
            result: result_parser(row)
          }
        });
      },
      formatItem: row_parser
    });
  }
};
Poema.Autocomplete.Roles = function(field) {
  var endpoint = Poema.Options.Get('JsBackendPath') + '/autocomplete_roles';
  var row_parser = function(row) {
    return row.description;
  };
  var res_parser = function(row) {
    return row.id;
  };
  Poema.Autocomplete.Add(field, endpoint, row_parser, res_parser);
};
Poema.Autocomplete.Localisation = function(field, map_canvas) {
  field = $("#" + field);
  if (field.length > 0) {
    var endpoint = Poema.Options.Get('JsBackendPath') + '/autocomplete_dict_localisation';
    var row_parser = function(row) {
      return row.city + ", " + row.province + ", " + row.country;
    };
    var on_change = null;
    if (map_canvas) {
      Poema.Google.Map.SetUp(map_canvas);
      on_change = function(val) {
        Poema.Google.Map.ClearMarkers(map_canvas);
        if (val.length > 2) {
          Poema.Google.Map.SetLocation(map_canvas, val);
        }
        if (val.split(',').length > 3) {
          Poema.Google.Map.SetZoom(map_canvas, 15);
        }
      };
      on_change(field.val());
    }
    Poema.Autocomplete.Add(field, endpoint, row_parser, null, on_change);
    Poema.Log("Setting localisation autocomplete into #" + field.attr('id'))
  }
};

Poema.Url = {};

Poema.Url.Current = {};
Poema.Url.Current.Get = function() {
  return $(location).attr('href');
};
Poema.Url.Current.Path = function() {
  var url = $.url.parse(Poema.Url.Current.Get());
  return url.protocol + '://' + url.host + url.path;
};

Poema.Url.GoTo = function(destination_url, timeout) {
  if (!timeout) {
    timeout = 300;
  }
  setTimeout(function() {
    var destination = $.url.parse(destination_url);
    if (Poema.Url.Current.Path() == (destination.protocol + '://' + destination.host + destination.path))
    {
      // Hack: jeśli kieruję na tę samą stronę (robimy reload) trzeba coś dodać do adresu, inaczej strona się nie odświeża
      // W poniższym przypadku dodaję unix timestamp
      var uxt = Math.round((new Date()).getTime() / 1000);
      var new_destination = {
        protocol: destination.protocol,
        host:     destination.host,
        path:     destination.path,
        params:   destination.params,
        anchor:   destination.anchor
      };
      if (new_destination.params) {
        new_destination.params = jQuery.extend({'uxt': uxt}, new_destination.params);
      }
      else {
        new_destination.params = {'uxt': uxt};
      }
      $(location).attr('href',$.url.build(new_destination));
    }
    else
    {
      $(location).attr('href',destination_url);
    }
  }, (timeout));
};

Poema.Url.GetForFormat = function(url, format) {
  var url_parts = $.url.parse(url);
  if (url_parts.query) {
    return (url_parts.path + '.' + format + '?' + url_parts.query);
  }
  else {
    return (url + '.' + format);
  }
};

Poema.Ajax = {};
Poema.Ajax.Load = function(url, into, success) {
  if (into.length) {
    into.html("<div class='loading_box'>Ładuję zawartość, proszę czekać...</div>");
    $.ajax({
      url: Poema.Url.GetForFormat(url, 'ajax'),
      success: function(data) {
        into.html(data);
        if (success) {
          success(data);
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        Poema.Log("Ajax.Load.Error: " + errorThrown);
        into.html(jqXHR.responseText);
      },
      failure: function(data) {
        Poema.Log("Ajax.Load.Failure: " + data);
        into.html("Wystąpił problem podczas ładowania zawartości");
      }
    });
  }
};

Poema.Json = {};
Poema.Json.Form = function(form, handle, on_success, on_cancel) {
  if (form.length) {
    Poema.Log("Json.Form: " + form.attr('method')  + '@' + form.attr('action'));
    if (on_cancel) {
      form.find('input:button').bind('click', on_cancel);
    }
    form.bind('submit', function(e) {
      e.preventDefault();
      Poema.Ui.SetWaiting(form, true);
      $.ajax({
        type: form.attr('method'),
        url: Poema.Url.GetForFormat(form.attr('action'), 'json'),
        data: $(this).serialize(),
        dataType: 'json',
        success: function(data) {
          Poema.Log("Json.Form: got success");
          Poema.Ui.SetWaiting(form, false);
          on_success(data);
        },
        error: function(data) {
          Poema.Log("Json.Form.Error: " + data.responseText);
          Poema.Ui.SetWaiting(form, false);
          $.each(jQuery.parseJSON(data.responseText), function(key, val) {
            if (handle) {
              var field = $('#'+handle+'_' + key);
              field.addClass('field_with_errors');
              field.attr('title', val);
              field.tooltip(Poema.Ui.Tooltip.OptionsDown());
            }
            else {
              // tutaj coś, co obsłuży formy bez handle, eg zrobi concat wszystkich błędów i wsadzi je do tooltipa
              // pod submitem
            }
          });
        },
        failure: function(data) {
          Poema.Log("Json.Form..Failure: " + data);
          Poema.Ui.SetWaiting(form, false);
        }
      });
      return false;
    });
  }
};

Poema.UserState = {};
Poema.UserState.Set = function(namespace, value) {
  $.ajax({
    type: 'POST',
    url: Poema.Options.Get('JsBackendPath') + '/state',
    data: {
      'authenticity_token': Poema.Options.Get('AuthenticityToken'),
      'namespace': namespace, 'value': value
    },
    dataType: "json"
  });                                
};
Poema.UserState.Get = function(namespace, success_callback) {
  $.ajax({
    url: Poema.Options.Get('JsBackendPath') + '/state',
    data: {
      'namespace': namespace
    },
    dataType: "json",
    success: function(data) {
      Poema.Log("Poema.UserState.Get: success: " + namespace + ". Result: " + data.results);
      success_callback(data.results)
    }
  });                                                                                                                    
};

Poema.Files = {};
Poema.Files.GetUploader = function(container_id, browse_button_id) {
  var uploader = new plupload.Uploader({
    runtimes : 'html5,flash',
    max_file_size: "200kb",
    filters : [
      {title : "Image files", extensions : "jpg,jpeg,gif,png"}
    ],
    browse_button : browse_button_id,
    container : container_id,
    url : Poema.Options.Get('JsBackendPath') + '/file_upload/session',
    flash_swf_url : Poema.Options.Get('AssetPath') + '/plupload.flash.swf',
    multipart_params: {
      'authenticity_token': Poema.Options.Get('AuthenticityToken')
    }
  });
  uploader.bind('Init', function(up, params) { Poema.Log("Poema.Files: current runtime: " + params.runtime); });
  return uploader;
};

Poema.Files.Single = function(container, browse_button) {
  var file_container = container.find('.file');
  var message_container = container.find('.message');

  if (container.length > 0 && browse_button.length > 0 && file_container.length > 0) {
    Poema.Log("Poema.Files.Single: setup");
    var uploader = Poema.Files.GetUploader(container.attr('id'), browse_button.attr('id'));
    uploader.init();
    uploader.bind('FilesAdded', function(up, files) {
      $.each(files, function(i, file) {
        message_container.html('Przesyłanie pliku ' + file.name + ' (' + plupload.formatSize(file.size) + '), czekaj...');
      });
      up.refresh();
      up.start();
    });
    uploader.bind('Error', function(up, err) {
      message_container.html("Przesyłanie pliku nie powiodło się, spróbuj ponowie lub zostaw to na później.");
      up.refresh();
    });
    uploader.bind('FileUploaded', function(up, file) {
      file_container._removeClass('hidden').html("<img src='" + Poema.Options.Get('JsBackendPath') + "/file_get_session'>");
      message_container.html("Gotowe.");
      setTimeout(function() { message_container.fadeOut("fast"); }, 1000);
    });
    Poema.UserState.Get("file_session_present", function(file_present) {
      if (file_present) {
        file_container._removeClass('hidden').html("<img src='" + Poema.Options.Get('JsBackendPath') + "/file_get_session'>");
      }
    })
  }
};

// Detekcja typu przeglądarki
Poema.UA = {};
Poema.UA.Chrome = function() {
  return /chrom(e|ium)/.test(navigator.userAgent.toLowerCase());
};
Poema.UA.GoogleBot = function() {
  return navigator.userAgent.toLowerCase().indexOf('googlebot') > 0;
};

Poema.Scroll = {};
Poema.Scroll.UsingAnchor = function(on_complete) {
  var url = $.url.parse(Poema.Url.Current.Get());
  var anchor = url.anchor;
  var target = $('*[data-anchor="' + anchor + '"]');
  if (target.length > 0) {
    Poema.Log("Scroll.UsingAnchor: scrolling to " + anchor);
    $(Poema.UA.Chrome() ? 'body' : 'html').animate({
      scrollTop: target.offset().top - 120   // Koryguję położenie o wysokość topu
    }, 1000, function() {
      if (null != on_complete) {
        on_complete(target);
      }
    });
  }
};