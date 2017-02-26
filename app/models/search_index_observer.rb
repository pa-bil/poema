class SearchIndexObserver < ActiveRecord::Observer
  observe :user, :container, :publication, :uploaded_file, :forum, :forum_thread, :forum_post, :calendar

  def after_create(record)
    raise "Missing search_index_content method" unless record.respond_to? :search_index_content
    unless (content = record.search_index_content).nil?
      idx = record.search_index
      if idx.nil?
        idx = record.build_search_index(:content => prepare_content(content))
        record.search_index = idx
      else
        idx.update_attributes!(:content => prepare_content(content))
      end
    end
  end

  def after_update(record)
    raise "Missing search_index_content method" unless record.respond_to? :search_index_content
    if record.search_index_content.nil?
      idx = record.search_index
      idx.destroy unless idx.nil?
    else
      after_create(record)
    end
  end

  def before_destroy(record)
    raise "Missing search_index_content method" unless record.respond_to? :search_index_content
    idx = record.search_index
    unless idx.nil?
      idx.destroy
    end    
  end

  include ActionView::Helpers::SanitizeHelper

  private

  def prepare_content(content)
    strip_tags(content.join(" ").strip)
  end
end
