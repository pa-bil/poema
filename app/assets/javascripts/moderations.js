Poema.Register(Poema.Moderations = {});

Poema.Moderations.Name = "Moderations";
Poema.Moderations.Init = function() {  return ($('#divModerations').length > 0); };
Poema.Moderations.Exec = function() {
  if ($(".new_moderation").length > 0) {
    Poema.Ui.Datepicker.IntoRailsDateField('moderation_expiry_date');
  }
};
