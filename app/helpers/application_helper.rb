# encoding: utf-8
module ApplicationHelper
  include Acl9Helpers

  # Content helper
  def url_add_hostname(url)
    "http://#{PoemaConfig.site_hostname}#{url}"
  end

  def safe_html(s)
    s = s.to_s
    s = s.gsub(/<script\b[^>]*>(.*?)<\/script>/i, '')
    s = s.gsub(/<embed\b[^>]*>(.*?)<\/embed>/i,   '')
    s = s.gsub(/<object\b[^>]*>(.*?)<\/object>/i, '')
    s = s.gsub(/<iframe\b[^>]*>(.*?)<\/iframe>/i, '')
    raw s
  end

  def mfword(male, female, user = nil)
    user = session_user if user.nil? && defined?(session_user)
    (!user.nil? && 'F' == user.gender) ? female : male
  end

  def cntword(num, osoba , osoby, osob)
    return osoba if num == 1
    return osoby if num > 1 && num <= 4
    return osob  if num <= 21

    mod = num%10

    return osoby if mod > 1 && mod <= 4
    osob
  end

  def nl2br(s)
    s = h s.to_s
    raw s.gsub(/\n/, '<br>')
  end

  def date_format(datetime, format = nil)
    if format.nil?
      I18n.localize datetime, {:format => :long}
    elsif format == :only_date
      I18n.localize datetime, {:format => "%d %B %Y"}
    else
      I18n.localize datetime, {:format => format}
    end
  end

  # Layout helper
  # @todo to można by zrefaktorować na jakieś page_options, które zmniejszy ilośc wywoływanych w szablonach metod

  def has_own_bg_for_main_content
    @main_content_has_own_bg = true
  end

  def main_content_own_bg?
    @main_content_has_own_bg
  end

  def title(title)
    content_for(:title) {
      truncate strip_tags(title.to_s), :length => 70  if title.to_s.length > 0
    }
  end

  def description(description)
    content_for(:description) {
      truncate strip_tags(description.to_s), :length => 160 if description.to_s.length > 0
    }
  end

  def show_title?
    @show_title
  end

  def js_option(option, value)
    @js_options = {} if @js_options.nil?
    @js_options.store(option, value)
  end

  def js_file_external(path)
    @js_files_ext = [] if @js_files_ext.nil?
    @js_files_ext.push(path)

    js = ''
    @js_files_ext.each do |f|
      js = js + "<script type=\"text/javascript\" src=\"#{f}\"></script>\n"
    end

    content_for(:js_files_external_body) {
      raw js
    }
  end

  NAVI_PATH_DELIMITER = "&#187;"

  def navi_path(*args)
    n = []
    args.each do |a|
      case a
        when Container
          n.concat container_navi_path(a, !args.last.instance_of?(Container))
        when Publication
          n.concat publication_navi_path(a, !args.last.instance_of?(Publication))
        when User
          n <<  (args.last.instance_of?(User) ? h(a.name) : link_to(a.name, user_path(a)))
        when Forum
          n << link_to(a.title, forum_path(a))
        when ForumThread
          n << link_to(a.title, forum_forum_thread_path(a.forum, a))
        when Calendar
          n.concat calendars_navi_path(a, (args.count > 1))
        else
          n << a
      end
    end

    content_for(:layout_navi_path) {
      p = ''
      n.each do |elem|
        p << "<li>#{NAVI_PATH_DELIMITER} #{elem}</li>"
      end
      raw p
    }
  end

  def is_new_link(o)
    unless (is_new = is_new(o)).nil?
      case o
        when Container
          link_to(is_new, index_publications_since_container_path(o))
        when Publication, Forum
          is_new
        else
          raise "Unknown object type"
      end
    end
  end

  def is_new(o)
    if session_user?
      case o
        when Container
          date = o.last_publication
        when Publication
          date = o.created_at
        when Forum
          date = o.last_activity_at
        when ForumThread
          date = o.counter_post > 0 ? o.last_activity_at : o.created_at
        else
          if o.respond_to? :created_at
            date = o.created_at
          else
            raise "Unknown object type"
          end
      end
      since = session_user.stat.last_visit_trimmed
      if date.nil? == false && date > since
        image_tag 'i/hot_red_folder.gif'
      end
    end
  end

  def content_copyright_select_options
    s = {I18n.t("activerecord.misc.select_empty_option") => 0}
    ContentCopyright.where('id > 1').each do |u|
      caption = I18n.t(u.title)
      s[caption] = u.id
    end

    s.sort{ |l, r| l[1]<=>r[1] }
    s
  end

  def facebook_like
    content_tag :iframe, nil, :src => "http://www.facebook.com/plugins/like.php?href=#{CGI::escape(request.url)}&send=false&layout=button_count&show_faces=false&width=450&action=recommend&font=verdana&colorscheme=light", :scrolling => 'no', :frameborder => '0', :allowtransparency => true, :class => :fb_like_iframe
  end

  def bool_to_human(val)
    return "tak" if (val == true)
    return "nie" if (val == false)
  end

  def delete_path_element
    '/usun'
  end
end
