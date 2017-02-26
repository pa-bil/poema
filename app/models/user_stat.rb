class UserStat < ActiveRecord::Base
  belongs_to :user

  LAST_VISIT_TRIGGER = 12

  def increment_forum_stats(last_forum_post)
    self.update_attribute :last_forum_post, last_forum_post
    self.class.increment_counter :counter_forum_post, self.id
  end

  def decrement_forum_stats
    self.class.decrement_counter :counter_forum_post, self.id
  end

  # Przycina czas wizyty do 7 dni, nie chcemy po długim czasie nieobecności pokazać userowi setek informacji
  def last_visit_trimmed
    l = last_visit
    l = 7.days.ago if l + 7.days < DateTime.current
    l
  end

  # Domyślnie zakładamy, że ostatnie logowanie
  def current_visit
    read_attribute(:current_visit) || LAST_VISIT_TRIGGER.hours.ago
  end
end
