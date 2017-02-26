Poema.Register(Poema.Publications = {});

Poema.Publications.Name = "Publications";
Poema.Publications.Init = function() { return ($('#divPublications').length > 0); };
Poema.Publications.Exec = function() {
  Poema.Scroll.UsingAnchor(function(target) {
    target.effect('highlight', 3000);
  });
  Poema.Ui.Wysiwyg($('#publication_content'));
  Poema.Comments.Init();
  Poema.Ui.Gallery();

  // Ukrywam pola zaawansowanego formularza, jeśli ustawiono opcję simpla
  if (Poema.Options.Get('PublicationSimpleForm')) {
    $('#publication_simple_button').removeClass('hidden').bind('click', function(e) {
      e.preventDefault();
      $('#divPublications').find('.extended_form').each(function() {
        $(this).removeClass('hidden');
      });
    });
    $('#divPublications').find('.extended_form').each(function() {
      $(this).addClass('hidden');
    });
  }

  if ($('#avatar_upload_container').length > 0) {
    Poema.Files.Single($('#avatar_upload_container'), $('#avatar_upload_publication_browse_button'));
  }

  var cpb = $('#publication_container_picker_button');
  if (cpb.length > 0 && cpb.attr('href')) {
    cpb.bind('click', function(e) {
      e.preventDefault();
      Poema.Containers.Picker.Init(cpb.attr('href'), function(container_id, title, link) {
        $('#publication_container_id').val(container_id);
        $('#publication_containers_picker_title').val(title);
        cpb.attr('href', link);
      });
    });
  }
};
