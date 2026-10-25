class BlockBadBots
  # Zmieniamy wyrażenie regularne na tekstowe sprawdzanie, bezpieczne dla starszych wersji Ruby
  # Rozszerzona lista botów (dodany seokicks, yandex i googleusercontent)
  BAD_BOTS = ["semrushbot", "petalbot", "dataforseobot", "blexbot", "seranking", "seokicks", "yandex", "googleusercontent"]
  
  BAD_IPS = [
    # Stare IP (wciąż potrzebne)
    '216.244.66.226', '136.243.228.177', '136.243.220.210',
    '80.241.219.114', '31.220.89.45', '80.241.221.60', '80.241.221.88',
    
    # NOWE IP Z WCZORAJSZYCH LOGÓW (Główni sprawcy):
    '144.76.151.45',  # Nowy rekordzista z Niemiec (317.4 MB)
    '142.132.135.121', # Drugi agresywny serwer Hetzner (85.6 MB)
    '185.177.72.69'    # Natrętny serwer z Francji (12.2 MB, 0% grafiki)
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    # Pobieramy nagłówki bezpośrednio ze środowiska (env), omijając potencjalne błędy Rack::Request
    user_agent = (env['HTTP_USER_AGENT'] || "").downcase
    client_ip = env['REMOTE_ADDR']

    # Sprawdzamy czy którykolwiek z botów znajduje się w User-Agent
    bot_detected = BAD_BOTS.any? { |bot| user_agent.include?(bot) }

    if bot_detected || BAD_IPS.include?(client_ip)
      # W starszych wersjach Rack nagłówki MUSZĄ być stringami, a body musi odpowiadać na metodę #each (stąd tablica)
      return [403, { 'Content-Type' => 'text/plain' }, ['Access Denied']]
    end

    @app.call(env)
  end
end
