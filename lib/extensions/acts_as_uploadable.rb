module Poema
  module ActsAsUploadable
    def uploadable?
      self.included_modules.include?(InstanceMethods)
    end

    def acts_as_uploadable
      return if uploadable?

      has_one :avatar_file, :class_name => 'UploadedFile', :primary_key => :avatar_uploaded_file_id, :foreign_key => :id, :dependent => :destroy

      before_destroy do |object|
        begin
          object.update_column :avatar_uploaded_file_id, nil
        rescue
          Rails.loger.info $!
        end
        true
      end

      include InstanceMethods
      extend ClassMethods
    end

    module ClassMethods

    end

    module InstanceMethods
      def avatar=(uploaded_file)
        if self.readonly?
          raise "Avatar doesn't match model" if uploaded_file.id != self.avatar_uploaded_file_id
          @avatar = uploaded_file
        else
          self.avatar_uploaded_file_id = uploaded_file.nil? ? nil : uploaded_file.id
        end
      end

      def avatar
        return nil if self.avatar_uploaded_file_id.nil?
        return @avatar unless @avatar.nil?

        self.avatar_file
      end

      def avatar?
        !self.avatar_uploaded_file_id.nil?
      end
    end
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, Poema::ActsAsUploadable
