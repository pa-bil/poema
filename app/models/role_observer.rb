class RoleObserver < ActiveRecord::Observer
  observe :user, :container, :publication, :uploaded_file, :forum, :forum_thread, :calendar

  def after_create(record)
    # Każdy z obiektów mających relację 'owner' automatycznie tworzy dla ownera uprawnienie
    if record.respond_to? :owner
      record.accepts_role!(:owner, record.owner)
    end
    
    # Wspieramy także metodę 'authorization_roles' pozwalającą na definiowanie dowolnych ról
    if record.respond_to? :authorization_roles
      record.authorization_roles.each do |role, subject|
        if subject.nil?
          record.accepts_role!(role)
        else
          record.accepts_role!(role, subject)
        end
      end
    end
  end

  def before_destroy(record)
    case record
      when User
        record.has_no_roles!
      else
        Role.select('roles_users.user_id as id, roles.name').where(:authorizable_type => record.class.name).where(:authorizable_id => record.id).joins('INNER JOIN roles_users ON roles_users.role_id = roles.id').each do |r|
          record.accepts_no_role!(r.name, User.find(r.id))
        end
    end
    true
  end
end
