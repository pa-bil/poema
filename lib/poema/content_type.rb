module Poema
  module ContentType
    OWNED_POEM  = 1 # Te są zarezerwowane dla wizarda
    OWNED_PROSE = 2
    OWNED_PHOTO = 3
    OWNED_ART   = 4
    
    OWNED_01 = 101 # Tem mówią, że coś ma jakiś typ owned
    OWNED_02 = 102
    OWNED_03 = 102
    OWNED_04 = 104
    OWNED_05 = 105
    
    CALENDAR = 9
    
    PUBLISH_CONTAINER = 1
    PUBLISH_CALENDAR  = 2
    
    def self.publication_mode_by_content_type(content_type)
      map = {
        OWNED_POEM  => PUBLISH_CONTAINER,
        OWNED_PROSE => PUBLISH_CONTAINER,
        OWNED_PHOTO => PUBLISH_CONTAINER,
        OWNED_ART   => PUBLISH_CONTAINER,
        CALENDAR    => PUBLISH_CALENDAR
      }
      raise "Unable to map content type to publication mode" unless map.key?(content_type)
      map.fetch(content_type)
    end
    
    def self.container_id_map
      {
        OWNED_POEM  => Poema::Application::custom_config(:container_id_poem),
        OWNED_PROSE => Poema::Application::custom_config(:container_id_prose),
        OWNED_PHOTO => Poema::Application::custom_config(:container_id_photo),
        OWNED_ART   => Poema::Application::custom_config(:container_id_art)
      }
    end
    
    def self.container_id_by_content_type(content_type)
      map = self.container_id_map
      raise "Unable to map content type to container id" unless map.key?(content_type)
      map.fetch(content_type)
    end
    
    def self.content_type_by_container_id(id)
      map = self.container_id_map
      map.each do |m_ct, m_id|
        return m_ct if m_id == id
      end
      nil
    end
    
    def self.is_image_content_type?(container_id)
      ct = self.content_type_by_container_id(container_id)
      if ct == OWNED_PHOTO || ct == OWNED_ART
        return true
      end
      false
    end
    
    def self.is_text_content_type?(container_id)
      false == self.is_image_content_type?(container_id)
    end
  end
end
