# EN
Sorry, that application do not offer multilingual interface - only polish language is supported.

# PL

## Poema
Oprogramowanie obsługujące serwis Poema.pl pozbawione cech charakterystycznych. 
Jest to pełnoprawne, działające oprogramowanie, uwolnione wraz z zamknięciem serwisu Poema.pl
Oprogramowanie nie oferuje interfejsu w języku innym niż polski.
 
## Wymogi licencyjne

Proszę dokładnie zapoznać się z wymogami licencyjnymi AGPL. Sugerowanym sposobem publikacji zwrotnej wszelkich zmian, w tym
zmian związanych z rebrandingiem oprogramowania jest Github. Sugeruję zmiany publikować w sklonowanym repozytorium. 

## Wymagania systemowe

* hosting/serwer Ruby On Rails - aplikacja działa z ``Passenger`` a także z ``Unicorn``
* baza danych MySQL
* miejsce na dysku na uploadowane pliki
* dostęp do Shella (kompilacja assetów)
 
## Wymagania związane z zewętrznymi usługami
  
* konto na [https://mailgun.com] - maile są dystrybuowane przez ich API
* klucze API dla Google Maps
* konto developera Facebook (integracja logowania FB)
* konto developera NK (zaloguj z NK)

## Instalacja

* Przekopiować pliki na serwer.
* utworzyć ``config/database.yml`` - konfiguracja bazy danych, przykładowy plik ``./config/database-default.yml``
* utworzyć ``config/application.yml`` zgodnie z potrzebami, uzupełnić o klucze API, adresy email, etc. przykładowy plik ``config/application-default.yml``
* upewnić się, że katalog ``tmp/`` oraz ``public/filestore`` ma prawa zapisu dla serwera pod którym działa oprogramowanie
* ``rake db:migrate``
* ``rake assets:precompile``
* uruchomić serwer aplikacyjny
* założyć konto pierwszego użytkownika (root), aktywować je i nadać mu uprawnienia administracyjne - nie jest zalecane, aby był to  regularny użytkownik - to raczej konto systemowe, przy czym kolejne operacje powinno się przeprowadzić po zalogowaniu na to konto
* ``rails c``
```
u = User.find(1)
u.has_role! :root
```
* przejść na adres ``/kontener/dodaj`` i dodać foldery dla Poezji, Prozy, Grafik, Zdjęć.
* Zaktualizować ``container_id_*`` w  ``config/application.yml`` o odpowiednie identyfikatory oraz ``user_id_root`` o id konta systemowego (1?) - każda zmiana w tym pliku wymaga restartu aplikacji

### Po każdej zmianie JS/CSS/dodaniu pliku

* ``rake assets:precompile``
* zrestartować serwer aplikacyjny

## Autor

Arkadiusz Kuryłowicz 2011-2014

Wydano 2017
