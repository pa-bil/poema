/*
 Obsługa ignorowania entera jako submit eventu, button wstecz jest pierwszym submitem
 i przechwytuje event cofając usera + autocomplete w kroku lokalizacji
 Dodatkowo autocomplete w polu lokalizacji (via autocomplete_user_localisation)
*/

Poema.Register(Poema.Signup = {});

Poema.Signup.Name = "Signup";
Poema.Signup.Init = function() { return ($('#divSignup').length > 0); };
Poema.Signup.Exec = function() {
  $('#divSignup').find('input, select').bind('keypress', function(e) {
    var code = (e.keyCode ? e.keyCode : e.which);
    if(code == 13) {
      e.preventDefault();
      $("#forward_button").trigger('click');
    }
  });
  Poema.Terms.LoadCurrentIntoFrame();
  Poema.Autocomplete.Localisation('user_localisation', 'localisation_map_canvas');
  
  // Uploader avatara
  if ($('#avatar_upload_container').length > 0) {
    Poema.Files.Single($('#avatar_upload_container'), $('#avatar_upload_container_browse_button'));
  }

  // To ładuje avatar z sesji, na stronie potwierdzającej rejestrację
  var confirmation_avatar_container = $('#confirmation_avatar_container');
  if (confirmation_avatar_container.length > 0) {
    Poema.UserState.Get("file_session_present", function(file_present) {
      if (file_present) {
        confirmation_avatar_container.html("<img src='" + Poema.Options.Get('JsBackendPath') + "/file_get_session'>");
      }
    });
  }
};
