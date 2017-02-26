class CreateSessionClearEvent < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `sessions` CHANGE `id` `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT"
    execute "CREATE
        DEFINER = CURRENT_USER
        EVENT
          sessions_clear
        ON SCHEDULE
          EVERY 1 DAY
        COMMENT 'Clears out inactive sessions table each hour.'
        DO
          DELETE FROM sessions WHERE updated_at < (NOW() - INTERVAL 1 DAY)"
  end

  def down
  end
end
