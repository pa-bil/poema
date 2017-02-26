Poema.Register(Poema.Frontpage = {});

Poema.Frontpage.Name = "Frontpage";
Poema.Frontpage.Init = function() { return ($('#divFrontPage').length > 0); };
Poema.Frontpage.Exec = function() {
  Poema.Ajax.Load('/feed', $('#feed-container'), function() {
    jQuery("span.timeago").timeago();
    $("#calendar_date_range_slider").slider({
      range: true,
      min: 0,
      max: 365,
      values: [ 0, 30 ],
      slide: function( event, ui ) {
        var d = new Date();
        var b = new Date(d.getTime() +  (ui.values[0]*24*60*60*1000));
        var e = new Date(d.getTime() +  (ui.values[1]*24*60*60*1000));
        $("#calendar_date_range").val(b + " -" + e);
      }
    });
  });
};
