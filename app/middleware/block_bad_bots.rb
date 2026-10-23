class BlockBadBots
  # Zmieniamy wyrażenie regularne na tekstowe sprawdzanie, bezpieczne dla starszych wersji Ruby
  BAD_BOTS = ["semrushbot", "petalbot", "dataforseobot", "blexbot", "seranking"]
  
  BAD_IPS = [
    '216.244.66.226', '136.243.228.177', '136.243.220.210',
    '80.241.219.114', '31.220.89.45', '80.241.221.60', '80.241.221.88'
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
