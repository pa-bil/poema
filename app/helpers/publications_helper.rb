# encoding: utf-8
module PublicationsHelper

  # Formatuje w widoku wyświetlaną nazwę autora: dodaje tłumacza, zamienia ownera na autora w razie potrzeby
  #
  # @param p Publication
  # @param with_link bool
  # @return string
  #
  def publication_author_display(p, with_link = false)
    if p.author.nil?
      d = p.owner.name
    else
      d = p.author
    end
    d = h(d)
    d = link_to_user(d, p.owner) if (with_link && p.content_copyright.id == Poema::StaticId::get(:content_copyright, :owner))

    if p.translator.nil?
      t = ''
    else
      t = h(p.translator)
      t = link_to_user(h(t), p.owner) if (with_link && p.content_copyright.id == Poema::StaticId::get(:content_copyright, :translation_owner))
      t = ", <i>tłum. " + t + "</i>"
    end

    raw(d) + raw(t)
  end

  # Trochę magii, to musi podmienić url publikacji, jeśli jest linkiem, path zwraca wszystko bez parametrów i fragmentów
  def publication_path(*args)
    publication = nil
    args.each do |a|
      publication = a if a.instance_of?(Publication)
    end
    raise "Unable to detect publication object in publication_path helper method" if publication.nil?
    
    if publication.link?
      begin
        uri = URI.parse(publication.link)
        if uri.host.nil? || uri.host.include?(PoemaConfig.site_hostname)
          uri.path
        else
          (uri.scheme.nil? ? 'http' : uri.scheme) + '://' + uri.host + (uri.path.nil? ? '' : uri.path)
        end
      rescue
        (publication_path publication) + '/invalid_link'
      end
    else
      super
    end    
  end

  def publication_url(*args)
    publication = nil
    args.each do |a|
      publication = a if a.instance_of?(Publication)
    end
    raise "Unable to detect publication object in publication_url helper method" if publication.nil?

    if publication.link?
      begin
        uri = URI.parse(publication.link)
        (uri.scheme.nil? ? 'http://' : '') + publication.link
      rescue
        (publication_path publication) + '/invalid_link'
      end
    else
      super
    end
  end
  
  def publication_navi_path(publication, last_as_link = false)
    container_navi_path(publication.container, true) << (last_as_link ? link_to(truncate(publication.title, :length => 40), publication) : truncate(publication.title, :length => 40))
  end

  def publication_status_icon(publication)
    icon = publication.can_show? ? "+" : ""
    icon+="." if !publication.visible?
    icon+="!" if publication.banned?
    icon+="c" if publication.content_copyright.prohibit_exposition?
    icon+="#" if !publication.container.can_show?
    icon
  end
end
