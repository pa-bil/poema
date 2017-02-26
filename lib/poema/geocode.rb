module Poema
  module Geocode
    def self.update_object(obj, results, full_address = false)
      raise "Object is un-geocodabled" unless obj.respond_to?(:localisation)
      
      nullify = false
      if obj.localisation.to_s.length > 2
        ch = (obj.new_record? || ((p = obj.class.find(obj.id)) && p.localisation != obj.localisation))  # sprawdzam czy dane lokalizacji się zmieniły
        if ch
          geo = results.first
          if geo                                                                                        # dane się zmieniły, mamy info o lokalizacji
            obj.longitude = geo.longitude
            obj.latitude = geo.latitude
            if full_address
              obj.localisation_geocoder = geo.address
            else
              obj.localisation_geocoder = "#{geo.city}, #{geo.state}, #{geo.country}"
            end
          else
            nullify = true                                                                              # dane się zmieniły, ale nie można odnaleźć
                                                                                                        # informacji geo
          end
        end
      else
        nullify = true                                                                                  # nie podano lokalizacji, usuwamy dane
      end
      obj.longitude = obj.latitude = obj.localisation_geocoder = nil if nullify
    end

    def self.precise(localisation)
      results = Geocoder.search(localisation)
      return nil if results.empty?

      geo = results.first
      "#{geo.city}, #{geo.state}, #{geo.country}"
    end
  end
end
