Poema.Register(Poema.SpecialActions = {});

Poema.SpecialActions.Name = "SpecialActions";
Poema.SpecialActions.Init = function() {  return ($('#divSpecialActions').length > 0); };
Poema.SpecialActions.Exec = function() {
  if ($(".new_special_action").length > 0 || $('.edit_special_action').length > 0) {
    Poema.Ui.Datepicker.IntoRailsDateField('special_action_start_date');
    Poema.Ui.Datepicker.IntoRailsDateField('special_action_finish_date');
  }
};
