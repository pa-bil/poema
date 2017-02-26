module Poema
  module ActsAsAuditable
    def is_auditable?
      self.included_modules.include?(InstanceMethods)
    end

    def acts_as_auditable(options = {})
      return if is_auditable?

      default_options = {:anonymous => false, :raise_on_validation_errors => false}
      options = default_options.merge(options)
      self.send(:define_method, "acts_as_auditable_options", proc { return options })

      has_many :audits, :as => :auditable

      include InstanceMethods
      extend ClassMethods

      before_validation :audit_before_validation

      after_create :audit_after_create
      after_update :audit_after_update
      before_destroy :audit_before_destroy
    end

    module ClassMethods

    end

    module InstanceMethods

      # Wywołane przed zapisaniem obiektu wymusza utworzenie rekordu audytu, zazwyczaj powinno się przekazać parametry
      # w rodzaju {:user => session_user, :ip => request.remote_ip}, priorytet i typ operacji zostanie ustawiony automatycznie
      def audit_params(data)
        @audit_record = audit_build data
      end

      def audit!(data)
        a = audit_build data
        a.save!
      end

      def audit(data)
        a = audit_build data
        if a.valid? && a.save
          a
        else
          a.errors.each {|err| errors.add(:audit_params_data, :invalid)}
          nil
        end
      end

      protected

      def audit_before_validation
        if audit_perform_callback?
          unless @audit_record.valid?
            self.errors = {} if self.errors.nil?
            @audit_record.errors.each {|key,error|
              self.errors.add(key, error)
            }
          end
        end
      end

      def audit_after_create
        if audit_perform_callback?
          @audit_record.event_type = Audit::EVENT_CREATE
          @audit_record.save!
          @audit_record = nil
        end
      end

      def audit_after_update
        if audit_perform_callback? && changed?
          @audit_record.event_type = Audit::EVENT_UPDATE
          @audit_record.save!
          @audit_record = nil
        end
      end

      def audit_before_destroy
        if audit_perform_callback?
          @audit_record.event_type = Audit::EVENT_DESTROY
          @audit_record.save!
          @audit_record = nil
        end
      end

      private

      def audit_perform_callback?
        @audit_record.instance_of?(Audit)
      end

      def audit_build(data)
        options = acts_as_auditable_options
        defaults= {:event_type => Audit::EVENT_OTHER, :level => Audit::LEVEL_INFO}

        a = Audit.new(defaults.merge(data))
        a.auditable = self
        a.user = data[:user] unless data[:user].nil?
        a.anonymous = options[:anonymous] ? true : false

        # migracja utworzy audyty z datą wsteczną
        if ENV['MIGRATION'] && data[:created_at]
          a.created_at = data[:created_at]
        end

        a
      end
    end
  end
end

# Extend ActiveRecord's functionality
ActiveRecord::Base.send :extend, Poema::ActsAsAuditable
