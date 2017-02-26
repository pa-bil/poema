# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register_alias "text/html", :ajax

# To jest trochę shitty, ale muszę obsługiwać legacy URLs, które mają rozszerzenia po poprzednim systemie
Mime::Type.register_alias "text/html", :php
Mime::Type.register_alias "text/html", :php3
