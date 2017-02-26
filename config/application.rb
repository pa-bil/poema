require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Poema
  class Application < Rails::Application
    def self.custom_config(key = nil, default = nil)
      @custom_config = YAML.load_file("#{Rails.root.to_s}/config/application.yml")[Rails.env] if @custom_config.nil?
      return @custom_config if key.nil?

      key = key.to_s
      return @custom_config.key?(key) ? @custom_config[key] : default
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += Dir["#{config.root}/app/forms/"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :search_index_observer, :role_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Warsaw'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :pl
    I18n.enforce_available_locales = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable and configure the asset pipeline
    config.assets.enabled = true
    config.assets.version = 1
    config.assets.precompile += %w(wysiwyg.css vendor.css vendor.js)
    
    # config.assets.initialize_on_precompile = false
    # config.assets.css_compressor = :scss
    # config.assets.js_compressor = :uglifier

    # Mails
    config.action_mailer.delivery_method = :mailgun
    config.action_mailer.mailgun_settings = {domain: custom_config(:smtp_mailgun_domain), api_key: custom_config(:smtp_mailgun_key)}
  end
end