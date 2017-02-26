class StatCounter < ActiveRecord::Base
  def self.list_daily(stat_counter_object, start_date = Date.new(2001, 7, 1), end_date = Date.current)
    self.connection.select_all(sanitize_sql(["
       SELECT EXTRACT(YEAR  FROM dates_seq.date) AS y,
              EXTRACT(MONTH FROM dates_seq.date) AS m,
              EXTRACT(DAY   FROM dates_seq.date) AS d,
              IFNULL(SUM(stat_counters.counter), 0) AS value
         FROM dates_seq
    LEFT JOIN stat_counters ON stat_counters.date = dates_seq.date AND stat_counters.stat_counter_object_id = ?
        WHERE dates_seq.date >= ?
          AND dates_seq.date <= ?
     GROUP BY dates_seq.date
     ORDER BY dates_seq.date", stat_counter_object.id, start_date, end_date]))
  end

  def self.list_monthly(stat_counter_object, start_date = Date.new(2001, 7, 1), end_date = Date.current)
    self.connection.select_all(sanitize_sql(["
       SELECT EXTRACT(YEAR  FROM dates_seq.date) AS y,
              EXTRACT(MONTH FROM dates_seq.date) AS m,
              1 AS d,
              IFNULL(SUM(stat_counters.counter), 0) AS value
         FROM dates_seq
    LEFT JOIN stat_counters ON stat_counters.date = dates_seq.date AND stat_counters.stat_counter_object_id = ?
        WHERE dates_seq.date >= ?
          AND dates_seq.date <= ?
     GROUP BY EXTRACT(YEAR_MONTH FROM dates_seq.date)
     ORDER BY dates_seq.date", stat_counter_object.id, start_date, end_date]))
  end
end