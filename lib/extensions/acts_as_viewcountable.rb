module Poema
  module ActsAsViewcountable
    def viewcountable?
      self.included_modules.include?(InstanceMethods)
    end

    def acts_as_viewcountable
      return if viewcountable?

      has_one :view_counter, :as => :viewcountable

      include InstanceMethods
      extend ClassMethods
    end

    module ClassMethods
      # tą metodą można do zapytania dołączyć wartości liczników odsłon, po to, aby nie odpytywać o pojedyncze rekordy
      # metoda doda do wyniku pole które interpretowane jest przez view_counter_value() zwracającą ilość odsłon
      def joins_view_counter(klass = nil)
        klass = self if klass.nil?

        q = self.select("#{klass.table_name}.*, view_counters.counter AS view_counter_value_db")
        q = q.joins("LEFT JOIN view_counters ON view_counters.viewcountable_id = #{klass.table_name}.id AND view_counters.viewcountable_type = '#{klass.name}'")
        q
      end
    end

    module InstanceMethods
      def view_counter_increment(amount = 1)
        amount = amount.to_i
        raise "View counter amount must be greather than zero" if amount < 1

        self.connection.exec_insert("INSERT INTO view_counters (viewcountable_id, viewcountable_type, counter) VALUES (#{self.id}, '#{self.class.name}', #{amount}) ON DUPLICATE KEY UPDATE counter=counter+#{amount}", 'ViewCounter Update', [])
      end

      def view_counter_value
        if self.respond_to? :view_counter_value_db
          value = self.view_counter_value_db.to_i
        else
          c = self.view_counter
          value = (c.nil? ? 0 : c.counter)
        end
        value
      end
    end
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, Poema::ActsAsViewcountable
