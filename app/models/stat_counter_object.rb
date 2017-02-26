class StatCounterObject < ActiveRecord::Base
  def self.increment_counter(handle, amount = 1, date = nil)
    raise "Unknown counter handle" if handle.to_s.empty?
    raise "Amount must be greater than zero" if amount < 1

    # temp fix
    return unless (handle =~ /view/).nil?
      
    o = self.find_or_create_by_handle(handle.to_s)
    d = date.nil? ? Date.current.strftime("%Y-%m-%d") : date.strftime("%Y-%m-%d")

    self.connection.exec_insert("INSERT INTO stat_counters (stat_counter_object_id, date, counter) VALUES (#{o.id}, '#{d}', #{amount.to_i}) ON DUPLICATE KEY UPDATE counter=counter+#{amount.to_i}", 'StatCounter Update', [])
  end
end
