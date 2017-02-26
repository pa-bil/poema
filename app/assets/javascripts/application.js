//= require_self
//= require_tree .

var Poema = {};

/**
 * Initialization, każdy kontener logiki działający w kontekście konkretnej strony, powinien posiadać
 * zdefiniowane funkcje Name, Init (ta zwraca true, jeśli kod powinien sie wykonać) oraz Exec wykonującą
 * właściwy kod
 */

Poema.Initializers = new Array();

Poema.Register = function(callback) {
  Poema.Initializers.push(callback);
};

Poema.Init = function() {
  Poema.Log("Initializer: starting");
  $.each(Poema.Initializers, function(index, initializer) {
    try {
      if (true == initializer.Init()) {
        initializer.Exec();
        Poema.Log("Initializer: " + initializer.Name + " executed");
      }
    }
    catch(err) {
      Poema.Log("Error during initialisation: " + err.message);
    }
  });
  Poema.Log("Initializer: finished");  
};

Poema.Log = function(line) {
  if (Poema.Options.Get('Debug')) {
    console.log(line);
  }
};

/**
 * Kontener danych i opcji opcje są dokładane w nagłówku do var poema_js_options
 */
 
Poema.Options = {};
Poema.Options.Set = function(variable, value) {
  poema_js_options[variable] = value;
};
Poema.Options.Get = function(variable) {
  return (poema_js_options[variable] != undefined ? poema_js_options[variable] : null);
};

/**
 * OnDomReady sprawdzamy wszystkie initializery
 * 
 */
$(document).ready(function() {
  Poema.Init();
});
