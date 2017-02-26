module ActiveRecord
  class Base
    def self.mysql2_connection(config)
      config[:username] = 'root' if config[:username].nil?
      config[:flags]    = Mysql2::Client::FOUND_ROWS if Mysql2::Client.const_defined? :FOUND_ROWS
      config[:flags]    = Mysql2::Client::COMPRESS
      
      client  = Mysql2::Client.new(config.symbolize_keys)
      options = [config[:host], config[:username], config[:password], config[:database], config[:port], config[:socket], 0]
      ConnectionAdapters::Mysql2Adapter.new(client, logger, options, config)
    end
  end
end