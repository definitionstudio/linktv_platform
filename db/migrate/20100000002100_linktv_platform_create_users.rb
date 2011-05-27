class LinktvPlatformCreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
      t.string   "display_name",                      :default => ""
      t.string   "email"
      t.string   "location"
      t.string   "login"
      t.integer  "login_count",                       :default => 0,     :null => false
      t.integer  "failed_login_count",                :default => 0,     :null => false
      t.datetime "current_login_at"
      t.datetime "last_login_at"
      t.string   "current_login_ip"
      t.string   "last_login_ip"
      t.integer  "request_count",                     :default => 0,     :null => false
      t.datetime "last_request_at"
      t.boolean  "privileged",                        :default => false, :null => false
      t.boolean  "active",                            :default => false, :null => false
      t.boolean  "deleted",                           :default => false, :null => false

      t.timestamps
    end

    add_index "users", ["email"], :name => "index_users_on_email"
    add_index "users", ["login"], :name => "index_users_on_login"
  end

  def self.down
    drop_table :users
  end
end
