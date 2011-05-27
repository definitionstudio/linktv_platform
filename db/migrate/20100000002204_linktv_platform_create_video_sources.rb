class LinktvPlatformCreateVideoSources < ActiveRecord::Migration
  def self.up
    create_table "video_sources", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
      t.string   "name"
      t.text     "description"
      t.string   "feed_url",           :limit => 1024
      t.string   "auth_username"
      t.string   "auth_password"
      t.boolean  "auto_accept_videos",                 :default => false, :null => false
      t.boolean  "active",                             :default => false, :null => false
      t.boolean  "deleted",                            :default => false, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :video_sources
  end
end
