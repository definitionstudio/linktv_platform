class LinktvPlatformCreateVideoPlayStats < ActiveRecord::Migration
  def self.up
	  create_table "video_play_stats", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "video_id"
	    t.integer  "video_segment_id"
      t.integer  "user_id"
	    t.string   "ip"
	    t.string   "http_user_agent"
	    t.string   "http_referer"
	    t.datetime "created_at"
	  end

	  add_index "video_play_stats", ["ip"], :name => "index_video_play_stats_on_ip"
	  add_index "video_play_stats", ["video_id"], :name => "index_video_play_stats_on_video_id"
	  add_index "video_play_stats", ["video_segment_id"], :name => "index_video_play_stats_on_video_segment_id"
	  add_index :video_play_stats, :user_id
  end

  def self.down
    drop_table :video_play_stats
  end
end
