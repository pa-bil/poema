Poema.Google = {};

// To musi być w globalnym scope
var _gaq = _gaq || [];

Poema.Google.GA = {};
Poema.Google.GA.Init = function() {
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  // Google ID
  ga('create', '', '');
  ga('send', 'event', 'View', 'ControllerAction', Poema.Options.Get('ControllerAction'));
  ga('set', 'contentGroup1', Poema.Options.Get('ControllerAction'));
  ga('send', 'event', 'User', 'Session', Poema.Options.Get('UserAuthenticated') ? 'Authenticated' : 'Anonymous');
  if (Poema.Options.Get('User')) {
    ga('send', 'event', 'User', 'Name', Poema.Options.Get('User'));
    ga('set', 'contentGroup2', Poema.Options.Get('User'));
  }
  ga('send', 'pageview');
};

// Obsługa map, koszmarnie brzydko jest to zrobione, kiedyś trzeba będzie przepisać lepiej
Poema.Google.Map = {};
Poema.Google.Map.Maps = [];
Poema.Google.Map.Markers = [];
Poema.Google.Map.Zoom = [];

Poema.Google.Map.SetUp = function(canvas_id) {
  var options = {
    center: new google.maps.LatLng(52.22840, 19.5),
    zoom: 5,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    disableDefaultUI: true
  };
  Poema.Google.Map.Maps[canvas_id] = new google.maps.Map(document.getElementById(canvas_id), options);
};

Poema.Google.Map.SetZoom = function(canvas_id, zoom) {
  Poema.Google.Map.Zoom[canvas_id] = zoom;

  var map = Poema.Google.Map.Maps[canvas_id];
  map.setZoom(zoom);
};

Poema.Google.Map.SetCoords = function(canvas_id, lat, lng) {
  var map = Poema.Google.Map.Maps[canvas_id];
  var coords = new google.maps.LatLng(lat, lng);

  map.setCenter(coords);
  var marker = new google.maps.Marker({
    map: map,
    position: coords
  });
  if (!Poema.Google.Map.Markers[canvas_id]) {
    Poema.Google.Map.Markers[canvas_id] = [];
  }
  Poema.Google.Map.Markers[canvas_id].push(marker);
};

Poema.Google.Map.SetLocation = function(canvas_id, location) {
  Poema.Log("Poema.Google.Map.SetLocation: " + location);
  var geocoder = new google.maps.Geocoder();
  geocoder.geocode( { 'address': location}, function(results, status) {
    if (status == google.maps.GeocoderStatus.OK) {
      var map = Poema.Google.Map.Maps[canvas_id];
      if (Poema.Google.Map.Zoom[canvas_id]) {
        map.setZoom(Poema.Google.Map.Zoom[canvas_id]);
      }
      else {
        map.setZoom(10);
      }
      map.setCenter(results[0].geometry.location);
        var marker = new google.maps.Marker({
          map: map,
          position: results[0].geometry.location
        });
      if (!Poema.Google.Map.Markers[canvas_id]) {
        Poema.Google.Map.Markers[canvas_id] = [];
      }
      Poema.Google.Map.Markers[canvas_id].push(marker);
    }
    else {
      Poema.Log("Poema.Google.Map.SetLocation: geocode was not successful for the following reason: " + status);
    }
  });
};

Poema.Google.Map.ClearMarkers = function(canvas_id) {
  if (Poema.Google.Map.Markers[canvas_id]) {
    for (i in Poema.Google.Map.Markers[canvas_id]) {
      Poema.Google.Map.Markers[canvas_id][i].setMap(null);
    }
  }
};
