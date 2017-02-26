module ContainersHelper
  def container_navi_path(container, last_as_link = false)
    n = []
    unless container.new_record?
      container.parents(last_as_link ? true : false).each do |c|
        n.push(link_to(c.title, container_path(c)))
      end
      n.push(h(container.title)) unless last_as_link
    end
    n
  end

  def container_status_icon(container)
    icon = container.can_show? && container.counter_publication > 0 ? "+" : ""
    icon+="." if !container.visible?
    icon+="!" if container.banned?
    icon+="#" if (!container.container.nil? && !container.container.can_show?)
    icon+="0" if container.counter_publication < 1
    icon
  end
end
