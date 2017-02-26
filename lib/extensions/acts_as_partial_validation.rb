# Dodaje do modelu możliwośc częsciowej walidacji aby móc przepychać go w wielokrokowych formularzach

module Poema
  module ActsAsPartialValidation
    def partial_validation?
      self.included_modules.include?(InstanceMethods)
    end

    def acts_as_partial_validation
      return if partial_validation?
      attr_writer :section

      include InstanceMethods
      extend ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods
      def section
        @section
      end

      def section? (section)
        return nil == self.section || section == self.section
      end

      def all_valid?
        self.section = nil
        self.valid?
      end
    end
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, Poema::ActsAsPartialValidation
