# Paranoid:
# rozszerzenie do markowania rekordów jako usuniętych, nie używa klasycznego 'default_scope' na modelu
# @fixme: to trzeba by wywalić, na rzecz standardowego  paranoid + Uncoped

module Poema
  module ActsAsParanoid
    def paranoid?
      self.included_modules.include?(InstanceMethods)
    end

    def acts_as_paranoid
      return if paranoid?

      # To nie może zamienić sie na callback after_find, ponieważ ten jest wywoływany podczas ładowania relacji,
      # i wykłada się z wyjątkiem, podczas eg. ładowania postów, które należały do usuniętego usera
      def self.find(*args)
        r = super(*args)
        if r.instance_of?(Array)
          r.each do |o|
            raise ActiveRecord::RecordNotFound.new "Record #{o.class.name}.#{o.id} is destroyed" if (false == o.class.with_deleted? && o.destroyed?)
          end
        else
          raise ActiveRecord::RecordNotFound.new "Record #{r.class.name}.#{r.id} is destroyed" if (false == r.class.with_deleted? && r.destroyed?)
        end
        r
      end

      include InstanceMethods
      extend ClassMethods
    end

    module ClassMethods
      def with_deleted(mode = true)
        @with_deleted = mode
        self
      end

      def with_deleted?
        @with_deleted.nil? ? false : @with_deleted
      end

      def find_with_deleted(*args)
        with_deleted
        result = find(*args)
        with_deleted false

        result
      end

      def recover(*args)
        @with_deleted = true
        r = self.find(*args)

        if r.instance_of? User
          r.deleted_at = nil
          r.save!
        elsif r.instance_of? Array
          r.each do |o|
            o.deleted_at = nil
            o.save!
          end
        end
        @with_deleted = false
      end

      def deletion_conditions(id_or_array)
        ["id in (?)", [id_or_array].flatten]
      end

      def delete(id_or_array)
        delete_all(deletion_conditions(id_or_array))
      end

      def delete_all(conditions = nil)
        update_all ["deleted_at = ?", delete_now_value], conditions
      end

      def paranoid_column
        :deleted_at
      end

      def paranoid_column_type
        :datetime
      end

      def dependent_associations
        self.reflect_on_all_associations.select {|a| [:destroy, :delete_all].include?(a.options[:dependent]) }
      end

      def delete_now_value
        Time.now
      end
    end

    module InstanceMethods
      def paranoid_value
        self.send(self.class.paranoid_column)
      end

      def destroy
        if paranoid_value.nil?
          with_transaction_returning_status do
            run_callbacks :destroy do            
              self.class.delete_all(self.class.primary_key.to_sym => self.id)
	      self.paranoid_value = self.class.delete_now_value
    	      self
    	    end    
          end
        end
      end

      def delete
        if paranoid_value.nil?
          with_transaction_returning_status do
            self.class.delete_all(self.class.primary_key.to_sym => self.id)
            self.paranoid_value = self.class.delete_now_value
            self
          end
        end
      end

      def deleted?
        !paranoid_value.nil?
      end

      alias_method :destroyed?, :deleted?

      private

      def paranoid_value=(value)
        self.send("#{self.class.paranoid_column}=", value)
      end
    end
  end
end
# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, Poema::ActsAsParanoid
