class SearchesController < ApplicationController

  access_control do
    allow all
  end

  def index
  end
  
  def result
    @publications = []
    @containers = []
    @users = []
    p = []
    c = []
    u = []

    if params[:q].length > 3
      q = SearchIndex.sanitize(params[:q])
      sql = "
   SELECT s.searchable_id, s.searchable_type, MATCH (s.content) AGAINST (" + q + " IN BOOLEAN MODE) AS score
     FROM search_indices s
    WHERE (MATCH (s.content) AGAINST (" + q + " IN BOOLEAN MODE))
 ORDER BY score
    LIMIT 100"
      SearchIndex.connection.select_all(sql.strip).each do |row|
        case row['searchable_type']
          when Publication.name
            p.push(row['searchable_id'])
          when Container.name
            c.push(row['searchable_id'])
          when User.name
            u.push(row['searchable_id'])
          else
            # do nothing, każdy nowy kontekst powinien zostać odpowiednio oprogramowany
            # @todo brakuje obsługi forum, fotek (see search_index_observer.rb)
        end
      end
    end

    if p.count > 0
      @publications = Publication.list_multi(p)
    end
    if c.count > 0
      @containers = Container.list_multi(c)
    end
    if u.count > 0
      @users = User.list_multi(u)
    end
    
    if (p.count + c.count + u.count) < 1
      add_notice I18n.t 'controller.search.no_records'
    end
  end
end
