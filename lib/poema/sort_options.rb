# Rozszerzenie wspierające modele z sortowaniem, definiuje identyfikatory sortowań, implementuje metodę
# zwracającą nazwę kolumny sortującej

module Poema
  module SortOptions
    SORT_NATURAL = 0
    SORT_BY_TITLE = 1
    SORT_BY_DATE = 2
    SORT_BY_VIEWS = 4
    SORT_BY_COMMENTS = 6

    def self.included receiver
      receiver.extend ClassMethods
    end

    module ClassMethods
      def get_sort_field(sort_id, default_sort_id = SORT_NATURAL)
        sort_ids = [SORT_NATURAL, SORT_BY_TITLE, SORT_BY_DATE, SORT_BY_VIEWS, SORT_BY_COMMENTS]

        raise "sort_fields method must be defined" unless self.respond_to?(:sort_fields)
        raise Poema::Exception::SortUnknownOption if default_sort_id.nil? || !sort_ids.include?(default_sort_id)

        (!sort_id.nil? && sort_fields[sort_id.to_i]) ? sort_fields[sort_id.to_i] : sort_fields[default_sort_id]
      end

      def sort_options
        m = {}
        o = {"activerecord.sort.name"    => SORT_BY_TITLE,
             "activerecord.sort.natural" => SORT_NATURAL,
             "activerecord.sort.date"    => SORT_BY_DATE,
             "activerecord.sort.views"   => SORT_BY_VIEWS,
             "activerecord.sort.comments"=> SORT_BY_COMMENTS}
        o.each_pair do |k,v|
          m[I18n.t k] = v
        end
        m
      end
    end
  end
end
