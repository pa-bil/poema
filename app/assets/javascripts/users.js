Poema.Register(Poema.Users = {});

Poema.Users.Name = "Users";
Poema.Users.Init = function() {  return ($('#divUsers').length > 0); };
Poema.Users.Exec = function() {
  Poema.Scroll.UsingAnchor(function(target) {
    target.effect('highlight', 3000);
  });
  Poema.Comments.Init();
  Poema.Ui.Gallery();
};
