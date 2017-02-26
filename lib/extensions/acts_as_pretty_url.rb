module Poema
  module ActsAsPrettyUrl
    def pretty_url?
      self.included_modules.include?(InstanceMethods)
    end

    def acts_as_pretty_url
      return if pretty_url?

      include InstanceMethods
      extend ClassMethods
    end

    module ClassMethods
    end

    module InstanceMethods      
      def slug
        encoding_options = {
          :invalid           => :replace, 
          :undef             => :replace,  
          :replace           => ''
        }
         
        if respond_to?(:pretty_url_slug)
          "#{id} #{pretty_url_slug}".to_url
        elsif respond_to?(:title)
          if RUBY_VERSION < "1.9"
            (id.to_s + ' ' + title.tr_pl_chars).to_url
          else
            (id.to_s + ' ' + title.tr_pl_chars.encode(Encoding.find('ASCII'), encoding_options)).to_url
          end
        else
          "#{id}".to_url
        end
      end
      
      def to_param
        slug
      end
    end
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, Poema::ActsAsPrettyUrl
