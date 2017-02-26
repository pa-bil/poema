/**
 * Rzeczy związane z regulaminem
 *
 */

Poema.Register(Poema.Terms = {});

Poema.Terms.LoadCurrentIntoFrame = function() {
  var terms_frame = $('#termsFrame');
  if (terms_frame.length) {
    Poema.Ajax.Load('/regulamin', terms_frame, function(data) {
      terms_frame.html(data);
    });
  }
};

Poema.Terms.Name = "Terms";
Poema.Terms.Init = function() { return ($('#divTermsAccept').length > 0); };
Poema.Terms.Exec = function() {
  Poema.Terms.LoadCurrentIntoFrame();
};
