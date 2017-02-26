// UI
Poema.Ui = {};

/**
 * Linkifier: zamienia wszystkie URle w treści na aktywne z target=_blank
 *
 */
Poema.Ui.Linkify = {};

Poema.Ui.Linkify.Init = function(at) {

};

/**
 * Tooltipy
 *
 */
Poema.Ui.Tooltip = {};

Poema.Ui.Tooltip.Options = function(options) {
  var defaults = {opacity:  0.9, effect: "fade", tipClass: 'tooltip_up'};
  if (options) {
    return $.extend(defaults, options);
  }
  else {
    return defaults;
  }
};
Poema.Ui.Tooltip.OptionsUp = function() {
  return Poema.Ui.Tooltip.Options();
};
Poema.Ui.Tooltip.OptionsDown = function() {
  return Poema.Ui.Tooltip.Options({position: ['bottom', 'center'], tipClass: 'tooltip_down'});
};

/**
 * Obsługa popupów z potwierdzeniami
 *
 */
Poema.Ui.Popup = {};

Poema.Ui.Popup.Container = function() {
  return $('#divPopupContainer');
};
Poema.Ui.Popup.Options = function (options) {
  var defaults =  {
    autoOpen:  false,
    position:  ['center', 50],
    close:     function(event, ui) { $(this).dialog('destroy') },
    show:      'fade',  // inne efekty psują pozycję dialogu, pojawia się w przypadkowych miejscach
    hide:      'fade',
    modal:     true,
    resizable: false
  };
  return $.extend(defaults, options);
};

Poema.Ui.Popup.MakeTransparent = function(dialog, click_action) {
  if (!click_action) {
    click_action = function() { dialog.dialog("close"); }
  }

  dialog.bind("dialogopen", function() {
    $('.ui-dialog-titlebar').addClass('hidden');
    $('.ui-dialog').addClass('ui-dialog-transparent');
    $('.ui-dialog').on("click", click_action);
    $('.ui-widget-overlay').on("click", click_action);
  });

  dialog.bind("dialogbeforeclose", function() {
    $('.ui-dialog-titlebar').removeClass('hidden');
    $('.ui-dialog').removeClass('ui-dialog-transparent');
    $('.ui-dialog').unbind();
    $('.ui-widget-overlay').unbind();
  });
};

/**
 * Obsługa boksów z informacjami przekazywanymi z eg. flash.notice, szukam
 * wszystkich divów klasy poema_animated_box i animuję je
 *
 */
Poema.Ui.AnimatedBox = {};
Poema.Ui.AnimatedBox.Animate = function(box) {
  if (box.length) {
    Poema.Log("Ui.AnimatedBox.Animate: " + box.attr('id'));
    setTimeout(function() { box.fadeIn("fast"); }, 500);
    setTimeout(function() { box.fadeOut('slow'); }, 10000);
  }
};

/**
 * Ustawia kursor waiting na wszystkich podrzędnych elementach top_element
 *
 * @param top_element
 * @param state
 */
Poema.Ui.SetWaiting = function(top_element, state) {
  if (state) {
    top_element.addClass('loading_cursor');
    top_element.find('*').addClass('loading_cursor');
  }
  else {
    top_element.removeClass('loading_cursor');
    top_element.find('*').removeClass('loading_cursor');
  }
};

/**
 * Nakłada na wybrane hrefy popup galerii, element powinien wyglądać mniej więcej tak:
 * <a rel="poema_gallery_image" href="url.do.pełnego.zdjęcia">[miniaturka albo cokolwiek]</a>
 *
 */
Poema.Ui.Gallery = function() {
  var elements = $("a[rel=poema_gallery_image]");
  var asset_path = Poema.Options.Get('AssetPath');
  var settings = {
    imageLoading:	 asset_path + '/lightbox-ico-loading.gif',
    imageBtnPrev:	 asset_path + '/lightbox-btn-prev.gif',
    imageBtnNext:	 asset_path + '/lightbox-btn-next.gif',
    imageBtnClose: asset_path + '/lightbox-btn-close.gif',
    imageBlank:		 asset_path + '/lightbox-blank.gif',
    txtImage:      "Obraz",
    txtOf:         "z"
  };
  elements.lightBox(settings);
};

Poema.Ui.Wysiwyg = function(elem) {
  if (elem.length > 0) {
    var func_remove_attrs = function(input) {
      var walk_the_dom = function walk(node, func) {
          func(node);
          node = node.firstChild;
          while (node) {
              walk(node, func);
              node = node.nextSibling;
          }
      };

      var wrapper = document.createElement('div');
      wrapper.innerHTML= input;
      walk_the_dom(wrapper, function(el) {
          if (el.removeAttribute) {
              el.removeAttribute('id');
              el.removeAttribute('style');
              el.removeAttribute('class');
          }
      });
      return wrapper.innerHTML
    };
    var func_on_remove_format_click = function() {
      // To zrobi standardowy reformat a później wszystkie atrybuty z tagów, tam pojawiają się różne śmieci
      this.removeFormat().setContent(func_remove_attrs(this.getContent()));
      Poema.Log("Poema.Ui.Wysiwyg: removed attrs on paste");
    };
    var config = {
      autoGrow: true,
      css: Poema.Options.Get('AssetPath') + '/wysiwyg.css',
      debug: Poema.Options.Get('Debug'),
      initialContent: '',
      plugins: {
        i18n: {
          lang: "pl"
        },
        rmFormat: {
          rmMsWordMarkup: true
        }
      },
      removeHeadings: true,
      rmUnusedControls: true,
      controls: {
        h1:                   { visible : true, groupIndex: 0 },
        h2:                   { visible : true, groupIndex: 0 },
        h3:                   { visible : true, groupIndex: 0 },
        paragraph:            { visible : true, groupIndex: 0 },
        bold:                 { visible : true },
        italic:               { visible : true },
        strikeThrough:        { visible : true },
        underline:            { visible : true },
        justifyLeft:          { visible : true },
        justifyCenter:        { visible : true },
        justifyRight:         { visible : true },
        justifyFull:          { visible : true },
        indent:               { visible : true },
        outdent:              { visible : true },
        subscript:            { visible : true },
        superscript:          { visible : true },
        insertOrderedList:    { visible : true },
        insertUnorderedList:  { visible : true },
        insertHorizontalRule: { visible : true },
        undo:                 { visible : true, groupIndex: 99 },
        redo:                 { visible : true, groupIndex: 99 },
        removeFormat:         { visible : true, groupIndex: 99, exec: func_on_remove_format_click },
        html:                 { visible : true, groupIndex: 99 }
      }
    };
    $.wysiwyg.rmFormat.enabled = true;
    elem.wysiwyg(config);

  }
};

/**
 * Datetimepicker
 */
Poema.Ui.Datepicker = {};
Poema.Ui.Datepicker.IntoRailsDateField = function(field_id) {
  var first = $("#" + field_id + "_1i");
  if (first.length > 0) {
    Poema.Log("Ui.Datepicker.IntoRailsDateField: " + field_id);

    var p = $('<input type="text" />').attr({style:'display: none;'});
    first.before(p);

    p.datepicker(Poema.Ui.Datepicker.Options({
        onSelect: function(selected_date) {
          var all = selected_date.split('-');
          $("#" + field_id + "_1i").val(all[0]);
          $("#" + field_id + "_2i").val(all[1]);
          $("#" + field_id + "_3i").val(all[2]);
        }
    }));
  }
};
Poema.Ui.Datepicker.Options = function(options)
{
  var defaults = {
    dayNamesMin:      ['Nd', 'Po', 'Wt', 'Śr', 'Cz', 'Pt', 'So'],
    monthNames:       ['Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec', 'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'],
    dateFormat:       "yy-m-d",
    showOn:           "button",
 		buttonImage:      Poema.Options.Get('AssetPath') + "/i/64/calendar.png",
 		buttonImageOnly:  true
  };
  return $.extend(options, defaults);
};
