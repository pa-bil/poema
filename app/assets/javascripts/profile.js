/*
 Obsługa autouzupełniania w polu lokalizacji via autocomplete_user_localisation
 */
Poema.Register(Poema.Profile = {});

Poema.Profile.Name = "Profile";
Poema.Profile.Init = function() { return ($('#divProfile').length > 0); };
Poema.Profile.Exec = function()
{
  var userdata_tab_id = 2;
  var map_initialised = false;
  
  $('#divProfileTabs').bind('tabsselect', function(event, ui) {
    Poema.UserState.Set('profile_tab_selected', ui.index);
  });

  $('#divProfileTabs').bind('tabsshow', function(event, ui) {
    if (map_initialised == false && ui.index == userdata_tab_id) {
      map_initialised = true;
      Poema.Autocomplete.Localisation("user_localisation", 'localisation_map_canvas');
    }
  });

  var get_state_callback = function(tab_number) {
    var tab;
    if (tab_number) {
      tab = tab_number;
    }
    else {
      tab = 0;
    }
    $("#divProfileTabs").tabs({collapsible: true, selected: tab});

    $("#divProfileTabsLoading").toggleClass('hidden');
    $("#divProfileTabs").toggleClass('hidden');
  };

  Poema.UserState.Get("profile_tab_selected", get_state_callback);


  // Uploader avatara
  var avatar_upload_container = $('#avatar_upload_container');
  if (avatar_upload_container.length > 0) {
    Poema.Files.Single(avatar_upload_container, $('#avatar_upload_container_browse_button'));
  }
};

