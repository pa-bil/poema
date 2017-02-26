class CreateDatesSeq < ActiveRecord::Migration
  def up
    execute "create table dates_seq (`date` date not null, PRIMARY KEY (`date`)) COLLATE='utf8_polish_ci' ENGINE=InnoDB"
    sql = <<-SQL
      create procedure populate_dates_seq(d1 date, d2 date)
      BEGIN
        declare d0 datetime;
        SET d0 = d1;
        REPEAT
          insert IGNORE into dates_seq (`date`) values (d0);
          set d0 = DATE_ADD(d0, interval 1 day);
        UNTIL d0 >= d2 END REPEAT;
      END
    SQL

    execute sql
    execute "CALL populate_dates_seq('2001-07-01', '2030-12-30')"
    execute "drop procedure populate_dates_seq"
  end

  def down
  end
end
