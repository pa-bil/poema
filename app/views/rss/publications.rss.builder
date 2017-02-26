xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Nowe publikacje w serwisie"
    xml.description "Lista ostatnio dodanych publikacji w serwisie"
    xml.link rss_publication_url

    for feed_element in @publications
      publication = feed_element.wrapped
      xml.item do
        xml.title "#{publication.owner.name}: #{publication.title}"
        xml.description ""
        xml.pubDate publication.published_at.to_s(:rfc822)
        xml.link url_add_hostname(url_for publication)
        xml.guid url_add_hostname(url_for publication)
      end
    end
  end
end
