class SpecialActionPublication < ActiveRecord::Base
  belongs_to :special_action
  belongs_to :publication

  validate :special_action_valid?
  validate :publication_valid?
  validate :uniq_publication_in_action?

  def self.list_feed(limit = 10)
    limit = limit.to_i
    result = {}

    query = joins(:special_action).
      where(:special_actions => {:visible => true, :deleted_at => nil, :send_notification => true}).
      where('special_action_publications.created_at >= ?', Date.current - 4.days).
      includes(:publication)

    query.keep_if{|sap| sap.publication.can_show? }.each do |sap|
      index = sap.special_action.id.to_s + sap.created_at.strftime('%Y%m%d')  # grupuję po akcji i dniu (24h)
      if result.has_key?(index)
        result[index].grouped_elements = sap
      else
        e = Poema::FeedElement.new(sap)
        e.sort_value = sap.created_at.end_of_day  # ustawiam datę sortowania na koniec dnia, po to, aby akcja była przypięta na górze
        result.store(index, e)
      end
    end

    result.values.slice(0, limit)
  end

  private

  def special_action_valid?
    a = nil
    a = SpecialAction.find_by_id(special_action_id) unless special_action_id.nil?

    errors.add(:special_action_id, :missing) if a.nil? || false == a.can_show?
  end

  def publication_valid?
    p = nil
    p = Publication.find_by_id(publication_id) unless publication_id.nil?

    errors.add(:publication_id, :missing) if p.nil? || false == p.can_show?
  end

  def uniq_publication_in_action?
    p = nil
    p = Publication.find_by_id(publication_id) unless publication_id.nil?
    if !p.nil? && !special_action_id.nil?
      errors.add(:publication_id, :duplicate) if p.special_actions.where(:id => special_action_id).first
    end
  end
end
