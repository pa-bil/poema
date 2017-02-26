# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141112084616) do

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "event_type",     :limit => 1,                  :null => false
    t.integer  "level",          :limit => 1,   :default => 1, :null => false
    t.integer  "user_id"
    t.string   "ip",             :limit => 254
    t.text     "description"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "audits", ["auditable_type", "auditable_id"], :name => "index_audits_on_auditable_type_and_auditable_id"
  add_index "audits", ["event_type"], :name => "index_audits_on_event_type"
  add_index "audits", ["level"], :name => "index_audits_on_level"
  add_index "audits", ["user_id"], :name => "index_audits_on_user_id"

  create_table "auths", :force => true do |t|
    t.string   "login",         :limit => 100,                :null => false
    t.string   "password",      :limit => 64
    t.string   "crypt",         :limit => 32,                 :null => false
    t.string   "nk_id",         :limit => 128
    t.string   "fb_id",         :limit => 128
    t.integer  "counter_login",                :default => 0, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "auths", ["fb_id", "deleted_at"], :name => "index_auths_on_fb_id_and_deleted_at"
  add_index "auths", ["id", "deleted_at"], :name => "index_auths_on_id_and_deleted_at"
  add_index "auths", ["login", "deleted_at"], :name => "index_auths_on_login_and_deleted_at"
  add_index "auths", ["login"], :name => "index_auths_on_login", :unique => true
  add_index "auths", ["nk_id", "deleted_at"], :name => "index_auths_on_nk_id_and_deleted_at"

  create_table "calendars", :force => true do |t|
    t.integer  "user_id",                                                     :null => false
    t.string   "title",                    :limit => 254,                     :null => false
    t.text     "description"
    t.string   "link",                     :limit => 254
    t.date     "start_date",                                                  :null => false
    t.time     "start_time"
    t.date     "finish_date"
    t.time     "finish_time"
    t.string   "localisation",             :limit => 1024,                    :null => false
    t.string   "localisation_geocoder",    :limit => 1024
    t.float    "longitude"
    t.float    "latitude"
    t.string   "venue",                    :limit => 254,                     :null => false
    t.integer  "avatar_uploaded_file_id"
    t.boolean  "banned",                                   :default => false, :null => false
    t.boolean  "visible",                                  :default => true,  :null => false
    t.boolean  "sticky",                                   :default => false, :null => false
    t.datetime "last_comment"
    t.integer  "counter_comment_neutral",                  :default => 0,     :null => false
    t.integer  "counter_comment_positive",                 :default => 0,     :null => false
    t.integer  "counter_comment_negative",                 :default => 0,     :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
  end

  add_index "calendars", ["banned", "visible", "deleted_at", "start_date", "finish_date"], :name => "calendars_b_v_da_s_f"
  add_index "calendars", ["banned", "visible", "deleted_at"], :name => "calendars_b_v_da"
  add_index "calendars", ["id", "deleted_at"], :name => "index_calendars_on_id_and_deleted_at"
  add_index "calendars", ["user_id"], :name => "calendars_user_id_fk"

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "commentable_id",                                     :null => false
    t.string   "commentable_type",                                   :null => false
    t.string   "name",             :limit => 254
    t.string   "email",            :limit => 100
    t.text     "content",                                            :null => false
    t.integer  "emotion",          :limit => 1,                      :null => false
    t.boolean  "banned",                          :default => false, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  add_index "comments", ["commentable_id", "commentable_type", "deleted_at"], :name => "comments_cid_ct_da"
  add_index "comments", ["commentable_type"], :name => "comments_commentable_type_fk"
  add_index "comments", ["user_id", "deleted_at"], :name => "comments_ui_da"

  create_table "containers", :force => true do |t|
    t.integer  "container_id"
    t.integer  "user_id",                                                               :null => false
    t.string   "title",                               :limit => 254,                    :null => false
    t.text     "intro"
    t.text     "description"
    t.integer  "sort",                                               :default => 0,     :null => false
    t.integer  "order_key"
    t.boolean  "banned",                                             :default => false, :null => false
    t.boolean  "visible",                                            :default => true,  :null => false
    t.string   "allow_comments",                      :limit => 1,   :default => "D",   :null => false
    t.integer  "avatar_uploaded_file_id"
    t.integer  "granted_container_creator_role_id"
    t.integer  "granted_publication_creator_role_id"
    t.integer  "counter_publication",                                :default => 0,     :null => false
    t.integer  "counter_container",                                  :default => 0,     :null => false
    t.datetime "last_publication"
    t.datetime "last_comment"
    t.integer  "counter_comment_neutral",                            :default => 0,     :null => false
    t.integer  "counter_comment_positive",                           :default => 0,     :null => false
    t.integer  "counter_comment_negative",                           :default => 0,     :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.boolean  "force_visibility",                                   :default => false, :null => false
  end

  add_index "containers", ["container_id", "banned", "visible", "counter_publication", "force_visibility", "deleted_at"], :name => "containers_c_b_v_cp_fv_da"
  add_index "containers", ["granted_container_creator_role_id"], :name => "containers_granted_container_creator_role_id_fk"
  add_index "containers", ["granted_publication_creator_role_id"], :name => "containers_granted_publication_creator_role_id_fk"
  add_index "containers", ["id", "banned", "visible", "deleted_at"], :name => "containers_id_b_v_da"
  add_index "containers", ["id", "deleted_at"], :name => "index_containers_on_id_and_deleted_at"
  add_index "containers", ["user_id", "deleted_at"], :name => "containers_u_da"

  create_table "content_copyrights", :force => true do |t|
    t.string   "title",               :limit => 254,                    :null => false
    t.text     "description"
    t.boolean  "prohibit_exposition",                :default => false, :null => false
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
  end

  add_index "content_copyrights", ["prohibit_exposition"], :name => "index_content_copyrights_on_prohibit_exposition"

  create_table "content_objects", :force => true do |t|
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "dates_seq", :primary_key => "date", :force => true do |t|
  end

  create_table "dict_cities", :force => true do |t|
    t.integer  "dict_country_id",                 :null => false
    t.integer  "dict_province_id"
    t.string   "city",             :limit => 254, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "dict_cities", ["dict_country_id"], :name => "dict_cities_dict_country_id_fk"
  add_index "dict_cities", ["dict_province_id"], :name => "dict_cities_dict_province_id_fk"

  create_table "dict_countries", :force => true do |t|
    t.string   "country",    :limit => 254, :null => false
    t.string   "code",       :limit => 2,   :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "dict_countries", ["code"], :name => "index_dict_countries_on_code", :unique => true

  create_table "dict_provinces", :force => true do |t|
    t.integer  "dict_country_id",                :null => false
    t.string   "province",        :limit => 254, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "dict_provinces", ["dict_country_id"], :name => "dict_provinces_dict_country_id_fk"

  create_table "forum_posts", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.integer  "forum_thread_id",                    :null => false
    t.integer  "forum_post_id"
    t.text     "content",                            :null => false
    t.boolean  "banned",          :default => false, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "forum_posts", ["forum_post_id", "deleted_at"], :name => "forum_post_p_da"
  add_index "forum_posts", ["forum_thread_id", "deleted_at"], :name => "forum_post_t_da"
  add_index "forum_posts", ["id", "deleted_at"], :name => "index_forum_posts_on_id_and_deleted_at"
  add_index "forum_posts", ["user_id", "deleted_at"], :name => "forum_post_u_da"

  create_table "forum_threads", :force => true do |t|
    t.integer  "forum_id",                                             :null => false
    t.integer  "user_id",                                              :null => false
    t.string   "title",              :limit => 254,                    :null => false
    t.text     "content",                                              :null => false
    t.integer  "counter_post",                      :default => 0,     :null => false
    t.datetime "last_activity_at",                                     :null => false
    t.integer  "last_forum_post_id"
    t.boolean  "banned",                            :default => false, :null => false
    t.boolean  "closed",                            :default => false, :null => false
    t.boolean  "sticky",                            :default => false, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.integer  "closed_by_user_id"
  end

  add_index "forum_threads", ["closed_by_user_id"], :name => "forum_threads_closed_by_user_id_fk"
  add_index "forum_threads", ["forum_id", "banned", "deleted_at"], :name => "forum_threads_f_b_da"
  add_index "forum_threads", ["id", "deleted_at"], :name => "index_forum_threads_on_id_and_deleted_at"
  add_index "forum_threads", ["last_forum_post_id"], :name => "forum_threads_last_forum_post_id_fk"
  add_index "forum_threads", ["user_id", "deleted_at"], :name => "forum_threads_u_da"

  create_table "forums", :force => true do |t|
    t.string   "title",                :limit => 254,                    :null => false
    t.text     "description"
    t.boolean  "banned",                              :default => false, :null => false
    t.boolean  "visible",                             :default => true,  :null => false
    t.boolean  "moderated",                           :default => false, :null => false
    t.boolean  "allow_html",                          :default => false, :null => false
    t.datetime "last_activity_at",                                       :null => false
    t.integer  "counter_post",                        :default => 0,     :null => false
    t.integer  "last_forum_thread_id"
    t.datetime "deleted_at"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "forums", ["banned", "visible", "deleted_at"], :name => "forums_b_v_da"
  add_index "forums", ["id", "deleted_at"], :name => "index_forums_on_id_and_deleted_at"
  add_index "forums", ["last_forum_thread_id"], :name => "forums_last_forum_thread_id_fk"

  create_table "migration_sec_container_map", :force => true do |t|
    t.integer "sec_id"
    t.integer "container_id"
  end

  create_table "moderations", :force => true do |t|
    t.integer  "moderateable_id",                     :null => false
    t.string   "moderateable_type",                   :null => false
    t.integer  "moderator_id",                        :null => false
    t.integer  "user_id"
    t.text     "reason"
    t.text     "complain"
    t.boolean  "active",            :default => true, :null => false
    t.date     "expiry_date"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "moderations", ["moderateable_id", "moderateable_type"], :name => "moderations_mid_mt"
  add_index "moderations", ["moderator_id"], :name => "moderations_moderator_id_fk"
  add_index "moderations", ["user_id"], :name => "moderations_user_id_fk"

  create_table "money_donation_actions", :force => true do |t|
    t.integer  "money_donated"
    t.integer  "money_target"
    t.string   "info_url"
    t.integer  "year"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "password_reminders", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.string   "email",        :limit => 254, :null => false
    t.string   "token",        :limit => 254, :null => false
    t.datetime "completed_at"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "password_reminders", ["token", "completed_at"], :name => "index_password_reminders_on_token_and_completed_at"
  add_index "password_reminders", ["token"], :name => "index_password_reminders_on_token", :unique => true
  add_index "password_reminders", ["user_id", "created_at"], :name => "index_password_reminders_on_user_id_and_created_at"

  create_table "publications", :force => true do |t|
    t.integer  "container_id",                                                      :null => false
    t.integer  "user_id",                                                           :null => false
    t.string   "title",                    :limit => 254,                           :null => false
    t.text     "intro"
    t.text     "content",                  :limit => 2147483647
    t.string   "author",                   :limit => 128
    t.string   "link",                     :limit => 254
    t.integer  "content_copyright_id",                           :default => 1,     :null => false
    t.boolean  "banned",                                         :default => false, :null => false
    t.boolean  "visible",                                        :default => true,  :null => false
    t.string   "allow_comments",           :limit => 1,          :default => "D",   :null => false
    t.integer  "avatar_uploaded_file_id"
    t.datetime "last_comment"
    t.integer  "counter_comment_neutral",                        :default => 0,     :null => false
    t.integer  "counter_comment_positive",                       :default => 0,     :null => false
    t.integer  "counter_comment_negative",                       :default => 0,     :null => false
    t.datetime "published_at"
    t.datetime "deleted_at"
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.string   "translator",               :limit => 128
  end

  add_index "publications", ["banned", "visible", "deleted_at", "published_at"], :name => "publications_b_v_da_pa"
  add_index "publications", ["container_id", "banned", "visible", "deleted_at"], :name => "publications_c_b_v_da"
  add_index "publications", ["content_copyright_id"], :name => "publications_content_copyright_id_fk"
  add_index "publications", ["id", "banned", "visible", "deleted_at"], :name => "publications_i_b_v_da"
  add_index "publications", ["id", "deleted_at"], :name => "index_publications_on_id_and_deleted_at"
  add_index "publications", ["user_id", "banned", "visible", "deleted_at"], :name => "publications_u_b_v_da"
  add_index "publications", ["user_id", "deleted_at"], :name => "publications_u_da"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 64,  :null => false
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.string   "description",       :limit => 254
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "roles", ["name", "authorizable_id", "authorizable_type"], :name => "index_roles_on_name_and_authorizable_id_and_authorizable_type", :unique => true

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "roles_users", ["role_id"], :name => "roles_users_role_id_fk"
  add_index "roles_users", ["user_id", "role_id"], :name => "index_roles_users_on_user_id_and_role_id", :unique => true

  create_table "search_indices", :force => true do |t|
    t.text     "content",         :limit => 2147483647
    t.integer  "searchable_id",                         :null => false
    t.string   "searchable_type",                       :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "search_indices", ["content"], :name => "fulltext_search_index"
  add_index "search_indices", ["searchable_id", "searchable_type"], :name => "index_search_indices_on_searchable_id_and_searchable_type"
  add_index "search_indices", ["searchable_type"], :name => "search_indices_searchable_type_fk"

  create_table "sessions", :force => true do |t|
    t.string   "session_id",                       :null => false
    t.text     "data",       :limit => 2147483647
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "special_action_publications", :force => true do |t|
    t.integer  "special_action_id", :null => false
    t.integer  "publication_id",    :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "special_action_publications", ["publication_id"], :name => "special_action_publications_publication_id_fk"
  add_index "special_action_publications", ["special_action_id"], :name => "special_action_publications_special_action_id_fk"

  create_table "special_actions", :force => true do |t|
    t.string   "title",                               :limit => 254,                    :null => false
    t.text     "description"
    t.string   "promoter_title",                      :limit => 254,                    :null => false
    t.text     "promoter_description"
    t.string   "icon_url",                            :limit => 254
    t.boolean  "visible",                                            :default => true,  :null => false
    t.integer  "granted_special_action_submitter_id"
    t.date     "start_date"
    t.time     "start_time"
    t.date     "finish_date"
    t.time     "finish_time"
    t.datetime "deleted_at"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.boolean  "send_notification",                                  :default => false, :null => false
  end

  add_index "special_actions", ["granted_special_action_submitter_id"], :name => "special_actions_granted_special_action_submitter_id_fk"
  add_index "special_actions", ["visible", "deleted_at", "start_date", "start_time", "finish_date", "finish_time"], :name => "special_actions_v_da_s_f"

  create_table "stat_counter_objects", :force => true do |t|
    t.string   "handle",      :limit => 32,                   :null => false
    t.string   "description", :limit => 254
    t.string   "color",       :limit => 16
    t.float    "multiplier",                 :default => 1.0, :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "stat_counter_objects", ["handle"], :name => "index_stat_counter_objects_on_handle", :unique => true

  create_table "stat_counters", :id => false, :force => true do |t|
    t.integer "stat_counter_object_id",                :null => false
    t.date    "date",                                  :null => false
    t.integer "counter",                :default => 0, :null => false
  end

  create_table "terms_accept_logs", :force => true do |t|
    t.integer  "user_id",          :null => false
    t.integer  "terms_version_id", :null => false
    t.boolean  "accepted"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "terms_accept_logs", ["terms_version_id"], :name => "terms_accept_logs_terms_version_id_fk"
  add_index "terms_accept_logs", ["user_id", "terms_version_id"], :name => "index_terms_accept_logs_on_user_id_and_terms_version_id", :unique => true

  create_table "terms_versions", :force => true do |t|
    t.boolean  "current",     :default => false, :null => false
    t.datetime "introduced",                     :null => false
    t.datetime "expired"
    t.text     "description"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "terms_versions", ["current"], :name => "index_terms_versions_on_current"

  create_table "uploaded_files", :force => true do |t|
    t.integer  "user_id",                                            :null => false
    t.integer  "uploadable_id",                                      :null => false
    t.string   "uploadable_type",                                    :null => false
    t.string   "file_file_name",       :limit => 254,                :null => false
    t.string   "file_content_type",    :limit => 64,                 :null => false
    t.integer  "file_file_size",                                     :null => false
    t.datetime "file_updated_at"
    t.text     "description"
    t.integer  "content_copyright_id",                :default => 1, :null => false
    t.datetime "last_commented"
    t.datetime "deleted_at"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  add_index "uploaded_files", ["content_copyright_id"], :name => "uploaded_files_content_copyright_id_fk"
  add_index "uploaded_files", ["uploadable_id", "uploadable_type", "deleted_at"], :name => "uploaded_files_uid_ut_da"
  add_index "uploaded_files", ["uploadable_type"], :name => "uploaded_files_uploadable_type_fk"
  add_index "uploaded_files", ["user_id", "deleted_at"], :name => "uploaded_files_ui_da"

  create_table "user_blacklists", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.integer  "blacklisted_user_id",                :null => false
    t.string   "reason",              :limit => 254
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "user_blacklists", ["blacklisted_user_id"], :name => "user_blacklists_blacklisted_user_id_fk"
  add_index "user_blacklists", ["user_id", "blacklisted_user_id"], :name => "index_user_blacklists_on_user_id_and_blacklisted_user_id", :unique => true

  create_table "user_ranks", :force => true do |t|
    t.integer "rank", :default => 0, :null => false
  end

  create_table "user_signup_activations", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.string   "code",          :limit => 64, :null => false
    t.datetime "signup_on",                   :null => false
    t.datetime "activation_on"
  end

  add_index "user_signup_activations", ["code"], :name => "index_user_signup_activations_on_code", :unique => true
  add_index "user_signup_activations", ["user_id"], :name => "user_signup_activations_user_id_fk"

  create_table "user_stats", :force => true do |t|
    t.integer  "user_id",                                   :null => false
    t.datetime "current_visit"
    t.datetime "last_visit"
    t.datetime "last_publication"
    t.datetime "last_commented"
    t.datetime "last_forum_post"
    t.integer  "counter_publication",        :default => 0, :null => false
    t.integer  "counter_container",          :default => 0, :null => false
    t.integer  "counter_forum_post",         :default => 0, :null => false
    t.integer  "counter_commented_neutral",  :default => 0, :null => false
    t.integer  "counter_commented_positive", :default => 0, :null => false
    t.integer  "counter_commented_negative", :default => 0, :null => false
    t.datetime "deleted_at"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

  add_index "user_stats", ["id", "deleted_at"], :name => "index_user_stats_on_id_and_deleted_at"
  add_index "user_stats", ["user_id", "deleted_at"], :name => "index_user_stats_on_user_id_and_deleted_at"

  create_table "user_update_logs", :force => true do |t|
    t.integer  "user_id",                   :null => false
    t.string   "field_name", :limit => 64,  :null => false
    t.string   "value",      :limit => 254, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "user_update_logs", ["user_id", "field_name"], :name => "index_user_update_logs_on_user_id_and_field_name"

  create_table "users", :force => true do |t|
    t.integer  "auth_id",                                                    :null => false
    t.boolean  "locked",                                  :default => true,  :null => false
    t.boolean  "banned",                                  :default => false, :null => false
    t.string   "name",                     :limit => 100,                    :null => false
    t.string   "gender",                   :limit => 1,                      :null => false
    t.text     "intro"
    t.text     "description"
    t.string   "email",                    :limit => 100,                    :null => false
    t.string   "im_gadugadu",              :limit => 50
    t.string   "im_tlen",                  :limit => 100
    t.string   "website",                  :limit => 254
    t.string   "localisation",             :limit => 254
    t.string   "localisation_geocoder",    :limit => 254
    t.float    "longitude"
    t.float    "latitude"
    t.boolean  "visible",                                 :default => true,  :null => false
    t.string   "allow_comments",           :limit => 1,   :default => "D",   :null => false
    t.boolean  "sendmails",                               :default => true,  :null => false
    t.datetime "last_comment"
    t.integer  "counter_comment_neutral",                 :default => 0,     :null => false
    t.integer  "counter_comment_positive",                :default => 0,     :null => false
    t.integer  "counter_comment_negative",                :default => 0,     :null => false
    t.integer  "terms_version_id"
    t.integer  "avatar_uploaded_file_id"
    t.integer  "quota",                                   :default => 0
    t.datetime "deleted_at"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
  end

  add_index "users", ["auth_id"], :name => "users_auth_id_fk"
  add_index "users", ["id", "deleted_at"], :name => "index_users_on_id_and_deleted_at"
  add_index "users", ["locked", "banned", "visible", "deleted_at"], :name => "index_users_on_locked_and_banned_and_visible_and_deleted_at"
  add_index "users", ["terms_version_id"], :name => "users_terms_version_id_fk"

  create_table "view_counters", :id => false, :force => true do |t|
    t.integer "viewcountable_id",                  :null => false
    t.string  "viewcountable_type",                :null => false
    t.integer "counter",            :default => 0, :null => false
  end

  add_foreign_key "audits", "users", :name => "audits_user_id_fk"

  add_foreign_key "calendars", "users", :name => "calendars_user_id_fk"

  add_foreign_key "comments", "content_objects", :name => "comments_commentable_type_fk", :column => "commentable_type"
  add_foreign_key "comments", "users", :name => "comments_user_id_fk"

  add_foreign_key "containers", "containers", :name => "containers_container_id_fk"
  add_foreign_key "containers", "roles", :name => "containers_granted_container_creator_role_id_fk", :column => "granted_container_creator_role_id"
  add_foreign_key "containers", "roles", :name => "containers_granted_publication_creator_role_id_fk", :column => "granted_publication_creator_role_id"
  add_foreign_key "containers", "users", :name => "containers_user_id_fk"

  add_foreign_key "dict_cities", "dict_countries", :name => "dict_cities_dict_country_id_fk"
  add_foreign_key "dict_cities", "dict_provinces", :name => "dict_cities_dict_province_id_fk"

  add_foreign_key "dict_provinces", "dict_countries", :name => "dict_provinces_dict_country_id_fk"

  add_foreign_key "forum_posts", "forum_posts", :name => "forum_posts_forum_post_id_fk"
  add_foreign_key "forum_posts", "forum_threads", :name => "forum_posts_forum_thread_id_fk"
  add_foreign_key "forum_posts", "users", :name => "forum_posts_user_id_fk"

  add_foreign_key "forum_threads", "forum_posts", :name => "forum_threads_last_forum_post_id_fk", :column => "last_forum_post_id"
  add_foreign_key "forum_threads", "forums", :name => "forum_threads_forum_id_fk"
  add_foreign_key "forum_threads", "users", :name => "forum_threads_closed_by_user_id_fk", :column => "closed_by_user_id"
  add_foreign_key "forum_threads", "users", :name => "forum_threads_user_id_fk"

  add_foreign_key "forums", "forum_threads", :name => "forums_last_forum_thread_id_fk", :column => "last_forum_thread_id"

  add_foreign_key "moderations", "users", :name => "moderations_moderator_id_fk", :column => "moderator_id"
  add_foreign_key "moderations", "users", :name => "moderations_user_id_fk"

  add_foreign_key "password_reminders", "users", :name => "password_reminders_user_id_fk"

  add_foreign_key "publications", "containers", :name => "publications_container_id_fk"
  add_foreign_key "publications", "content_copyrights", :name => "publications_content_copyright_id_fk"
  add_foreign_key "publications", "users", :name => "publications_user_id_fk"

  add_foreign_key "roles_users", "roles", :name => "roles_users_role_id_fk"
  add_foreign_key "roles_users", "users", :name => "roles_users_user_id_fk"

  add_foreign_key "special_action_publications", "publications", :name => "special_action_publications_publication_id_fk"
  add_foreign_key "special_action_publications", "special_actions", :name => "special_action_publications_special_action_id_fk"

  add_foreign_key "special_actions", "roles", :name => "special_actions_granted_special_action_submitter_id_fk", :column => "granted_special_action_submitter_id"

  add_foreign_key "stat_counters", "stat_counter_objects", :name => "stat_counters_stat_counter_object_id_fk"

  add_foreign_key "terms_accept_logs", "terms_versions", :name => "terms_accept_logs_terms_version_id_fk"
  add_foreign_key "terms_accept_logs", "users", :name => "terms_accept_logs_user_id_fk"

  add_foreign_key "uploaded_files", "content_copyrights", :name => "uploaded_files_content_copyright_id_fk"
  add_foreign_key "uploaded_files", "content_objects", :name => "uploaded_files_uploadable_type_fk", :column => "uploadable_type"
  add_foreign_key "uploaded_files", "users", :name => "uploaded_files_user_id_fk"

  add_foreign_key "user_blacklists", "users", :name => "user_blacklists_blacklisted_user_id_fk", :column => "blacklisted_user_id"
  add_foreign_key "user_blacklists", "users", :name => "user_blacklists_user_id_fk"

  add_foreign_key "user_ranks", "users", :name => "user_ranks_id_fk", :column => "id"

  add_foreign_key "user_signup_activations", "users", :name => "user_signup_activations_user_id_fk"

  add_foreign_key "user_stats", "users", :name => "user_stats_user_id_fk"

  add_foreign_key "user_update_logs", "users", :name => "user_update_logs_user_id_fk"

  add_foreign_key "users", "auths", :name => "users_auth_id_fk"
  add_foreign_key "users", "terms_versions", :name => "users_terms_version_id_fk"

end
