Poema.Register(Poema.Calendars = {});

Poema.Calendars.Name = "Calendars";
Poema.Calendars.Init = function() {  return ($('#divCalendars').length > 0); };
Poema.Calendars.Exec = function() {
  if ($(".new_calendar").length > 0 || $('.edit_calendar').length > 0) {
    Poema.Autocomplete.Localisation('calendar_localisation', 'localisation_map_canvas');
    Poema.Ui.Wysiwyg($('#calendar_description'));
    Poema.Ui.Datepicker.IntoRailsDateField('calendar_start_date');
    Poema.Ui.Datepicker.IntoRailsDateField('calendar_finish_date');
  }
  if ($(".calendar_show").length > 0) {
    Poema.Scroll.UsingAnchor(function(target) {
      target.effect('highlight', 3000);
    });
    Poema.Ui.Gallery();
    Poema.Comments.Init();
  }
  if ($("#localisation_map_canvas").length > 0) {
    var canvas = 'localisation_map_canvas';

    Poema.Google.Map.SetUp(canvas);
    if (Poema.Options.Get('CalendarShowLat') && Poema.Options.Get('CalendarShowLon')) {
      Poema.Google.Map.SetZoom(canvas, 15);
      Poema.Google.Map.SetCoords(canvas, Poema.Options.Get('CalendarShowLat'), Poema.Options.Get('CalendarShowLon'));
    }
  }
  // Uploader avatara
  if ($('#avatar_upload_container').length > 0) {
    Poema.Files.Single($('#avatar_upload_container'), $('#avatar_upload_calendar_browse_button'));
  }
};
