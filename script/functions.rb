# encoding: utf-8

def putsnb(s)
  puts Time.now.strftime("%H:%M:%S") + ': ' + s
  $stdout.flush
end

def get_app_config
  OpenStruct.new(YAML.load_file("#{Rails.root.to_s}/config/database.yml")[Rails.env])
end

def get_sql_connection
  config_app = get_app_config
  Mysql2::Client.new(
    :host       => config_app.host,
    :username   => config_app.username,
    :password   => config_app.password,
    :database   => config_app.database,
    :encoding   => config_app.encoding,
    :sslkey     => config_app.sslkey,
    :sslcert    => config_app.sslcert,
    :sslca      => config_app.sslca,
    :sslverify  => true
  )
end