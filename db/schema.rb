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

ActiveRecord::Schema.define(:version => 20110609220819) do

  create_table "activations_obsolete", :force => true do |t|
    t.integer "user_id",               :null => false
    t.string  "code",    :limit => 16, :null => false
  end

  create_table "apis", :force => true do |t|
    t.string  "key",     :limit => 64,                 :null => false
    t.string  "server",  :limit => 64,                 :null => false
    t.integer "user_id",                               :null => false
    t.string  "channel", :limit => 12, :default => "", :null => false
  end

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "contents", :force => true do |t|
    t.string "country", :limit => 256
    t.string "city",    :limit => 256
    t.text   "content"
  end

  create_table "intersections", :force => true do |t|
    t.integer "polyline_id"
    t.integer "joint_id"
    t.float   "at_distance"
  end

  create_table "joints", :force => true do |t|
    t.float  "lat"
    t.float  "lng"
    t.string "joint_type", :limit => 12
  end

  create_table "keywords", :force => true do |t|
    t.string  "country", :limit => 256, :null => false
    t.string  "city",    :limit => 256, :null => false
    t.integer "owner",                  :null => false
  end

  create_table "links", :force => true do |t|
    t.integer "keyword_id",   :null => false
    t.text    "link",         :null => false
    t.text    "link_text",    :null => false
    t.text    "link_comment", :null => false
  end

  create_table "polylines", :force => true do |t|
    t.integer "user_id"
    t.text    "poly_points"
    t.text    "poly_levels"
    t.integer "poly_numLevels"
    t.integer "poly_zoomFactor"
    t.float   "bound_north"
    t.float   "bound_west"
    t.float   "bound_south"
    t.float   "bound_east"
  end

  create_table "routes", :force => true do |t|
    t.integer "video_id"
    t.integer "play_order"
    t.integer "polyline_id"
    t.integer "video_direction",     :limit => 1
    t.float   "start_at_distance"
    t.float   "end_at_distance"
    t.text    "start_placemark_de"
    t.text    "start_placemark_en"
    t.text    "end_placemark_de"
    t.text    "end_placemark_en"
    t.text    "start_locality_de"
    t.text    "start_locality_en"
    t.text    "end_locality_de"
    t.text    "end_locality_en"
    t.text    "start_country_de"
    t.text    "start_country_en"
    t.text    "end_country_de"
    t.text    "end_country_en"
    t.string  "start_country_code",  :limit => 16
    t.string  "end_country_code",    :limit => 16
    t.string  "start_locality_code", :limit => 16
    t.string  "end_locality_code",   :limit => 16
    t.integer "map_type",            :limit => 1,  :default => 1
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string "property", :limit => 32, :null => false
    t.string "value",    :limit => 32, :null => false
  end

  create_table "syncronisations", :force => true do |t|
    t.integer "route_id", :null => false
    t.float   "time",     :null => false
    t.float   "distance", :null => false
  end

  create_table "twitter", :force => true do |t|
    t.integer "user_id",                          :null => false
    t.integer "twitter_user_id",                  :null => false
    t.string  "screen_name",        :limit => 32, :null => false
    t.text    "oauth_token",                      :null => false
    t.text    "oauth_token_secret",               :null => false
  end

  create_table "uploads", :force => true do |t|
    t.integer  "user_id",                                                :null => false
    t.string   "content_type",        :limit => 64,                      :null => false
    t.string   "filename",            :limit => 64,                      :null => false
    t.integer  "size",                                                   :null => false
    t.integer  "video_flash_present", :limit => 1,  :default => 0,       :null => false
    t.integer  "video_thumb_present", :limit => 1,  :default => 0,       :null => false
    t.integer  "video_img_present",   :limit => 1,  :default => 0,       :null => false
    t.integer  "transcoder_state",    :limit => 1,  :default => 0,       :null => false
    t.integer  "width",                             :default => 0,       :null => false
    t.integer  "height",                            :default => 0,       :null => false
    t.integer  "PARX",                              :default => 1,       :null => false
    t.integer  "PARY",                              :default => 1,       :null => false
    t.integer  "DARX",                              :default => 4,       :null => false
    t.integer  "DARY",                              :default => 3,       :null => false
    t.float    "duration",                          :default => 2.0,     :null => false
    t.text     "name",                                                   :null => false
    t.text     "transcoder_message"
    t.datetime "submitted_at",                                           :null => false
    t.string   "terms_accepted",      :limit => 3,  :default => "NO",    :null => false
    t.string   "movement_type",       :limit => 8,  :default => "MISC",  :null => false
    t.string   "code",                :limit => 5,  :default => "00000", :null => false
    t.text     "encoder_output"
    t.boolean  "video_public",                      :default => false,   :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "firstname",                 :limit => 64
    t.string   "lastname",                  :limit => 64
    t.string   "login",                     :limit => 16
    t.string   "crypted_password",          :limit => 64
    t.text     "comment"
    t.datetime "last_login"
    t.string   "email",                     :limit => 45, :default => "",     :null => false
    t.string   "salt",                      :limit => 64, :default => "",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 45
    t.datetime "remember_token_expires_at"
    t.string   "role",                      :limit => 45, :default => "USER", :null => false
    t.string   "activation_code",           :limit => 64, :default => "BETA"
    t.string   "language",                  :limit => 8,  :default => "de",   :null => false
    t.boolean  "blocked",                                 :default => false,  :null => false
    t.boolean  "activated",                               :default => false,  :null => false
    t.boolean  "activation_mail_sent",                    :default => false,  :null => false
    t.integer  "upload_errors_count",                     :default => 0
    t.text     "upload_errors_latest"
    t.string   "website",                   :limit => 64
  end

  create_table "videos", :force => true do |t|
    t.integer  "user_id"
    t.string   "name",            :limit => 64
    t.float    "duration"
    t.string   "movement_type",   :limit => 8,  :default => "MISC", :null => false
    t.string   "filename_flash",  :limit => 64
    t.string   "filename_thumb",  :limit => 64,                     :null => false
    t.integer  "width",                         :default => 0
    t.integer  "height",                        :default => 0
    t.string   "filename_img",    :limit => 64,                     :null => false
    t.integer  "upload_id"
    t.integer  "DARX",                          :default => 4,      :null => false
    t.integer  "DARY",                          :default => 3,      :null => false
    t.integer  "PARX",                          :default => 1,      :null => false
    t.integer  "PARY",                          :default => 1,      :null => false
    t.boolean  "public",                        :default => true,   :null => false
    t.integer  "times_played",                  :default => 0
    t.datetime "latest_playback"
    t.boolean  "blocked",                       :default => false
    t.boolean  "youtube",                       :default => false
    t.boolean  "disabled",                      :default => false,  :null => false
    t.integer  "disabled_cause"
    t.text     "description"
  end

  create_table "waypoints", :force => true do |t|
    t.integer "polyline_id", :null => false
    t.text    "waypoints",   :null => false
  end

end
