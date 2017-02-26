class PublicationLimitValidator< ActiveModel::Validator
  def validate(publication)
    # podczas migracji nie sprawdzamy tego limitu
    return if ENV['MIGRATION']
    
    # dla publikacji ukrytych nie sprawdzamy limitu, użytkownik może sobie dodawać brudnopisy   
    return if !publication.visible?
    
    # Publikacje nie przypisane do kontenera lub ownera nie mają podstaw limitowania
    return if publication.container.nil? || publication.owner.nil?
    
    # nie sprawdzamy niczego dla publikacji dodanych poza limitowanym kontenerem
    return if !is_limited_container(publication.container)
        
    # jeśli ta publikacja nie była jeszcze publikowana (jest nowa, tudzież została dodana jako niewidoczna) zliczam publikacje dodane w dziale debiutów w ciągu ostatnich 24h
    if publication.published_at.nil?
      count = 0
      publication.owner.owned_publications.where(:deleted_at => nil).where("published_at > DATE_SUB(NOW(), INTERVAL 1 DAY)").each do |p|
        if is_limited_container(p.container)
          count = count + 1
        end
      end    
      publication.errors.add(:user_id, :over_limit) if count >= 1
    end
  end
  
  protected
  
  def is_limited_container(container)
    top_level_container_id = container.top_level_container.id
    Poema::ContentType::container_id_map.values.uniq.each {|container_id|
      return true if top_level_container_id == container_id
    }
    false
  end
end
