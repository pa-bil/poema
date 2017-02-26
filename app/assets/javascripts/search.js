Poema.Register(Poema.Search = {});

Poema.Search.Name = "Search";
Poema.Search.Init = function() { return ($('#divSearch').length > 0); };
Poema.Search.Exec = function() {
  $('#q').bind('keypress', function(e) {
    var code = (e.keyCode ? e.keyCode : e.which);
    if(code == 13) {
      e.preventDefault();
      $("#content_search").trigger('submit');
    }
  });
  $('#search_more').bind('click', function() {
    $('#search_syntax').toggleClass('hidden', 'visible');
  });
};
