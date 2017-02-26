module Poema
  module ModelCommon
    module ClassMethods

    end
      
    module InstanceMethods
      # Te metody można wywołać na łańcuchu zapytań, po to, aby załadować (eager loader) wszelkie dane
      def includes_owner_param
        {:owner => [:rank, {:avatar_file => [:content_copyright]} ]}
      end
      def includes_owner
        self.includes(includes_owner_param)
      end

      # Tę metodę można użyć w zasadzie wyłacznie w zapytaniach ładujących dane z tabeli publikacji, dołącza informacje o dołączeniu
      # publikacji do akcji specjalnej via has_special_action?
      def includes_special_action_existence
        join = 'LEFT JOIN special_action_publications ON (special_action_publications.publication_id = publications.id)'
        select = 'GROUP_CONCAT(special_action_publications.special_action_id) AS special_action_list'
        group = 'publications.id'

        self.select(select).joins(join).group(group)
      end
    end

    include InstanceMethods
    extend ClassMethods
  end
end

ActiveRecord::Base.send :extend, Poema::ModelCommon
