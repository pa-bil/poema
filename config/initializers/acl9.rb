Acl9::config.merge!({
  :default_role_class_name    => 'Role',
  :default_subject_class_name => 'User',
  :default_join_table_name    => 'roles_users',
  :cache                      => false,
})
