# Klasa do mapowania statycznych identyfikatorów obiektów (numery kontenerów, działów, numery użytkowników, etc)
module Poema
  module StaticId
    # Wyszkuję identyfikator obiektu object pierwsze w mapie specyficznej dla środowiska, później w mapie wspólnej
    # dla wszystkich środowisk
    def self.get(object, name)
      map_default = {
        :user => {
          :root               => Poema::Application::custom_config(:user_id_root)
        },
        :content_copyright => {
          :notset             => 1,
          :dontknow           => 2,
          :owner              => 3,
          :permitted          => 5,
          :translation_owner  => 7
        }
      }
   
      if Rails.env == 'development' || Rails.env == 'demo'
        map_env = {
          :container  => {
            :help => 1
          }
        }
      else
       map_env =  {
          :container  => {
            :help => 2496
          }
        }
      end
      
      r = nil
      r = map_env[object][name] unless map_env[object].nil?
      if r.nil?
        r = map_default[object][name] unless map_default[object].nil?
      end
      r
    end
  end
end
