class LinktvPlatformCreateVideos < ActiveRecord::Migration
  def self.up
	  create_table "videos", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "imported_video_id"
	    t.string   "name"
	    t.text     "description"
	    t.string   "permalink"
	    t.integer  "duration"
	    t.string   "media_type", :limit => 40
	    t.text     "transcript_text"
	    t.datetime "source_published_at"
      t.string   "source_name"
      t.string   "source_link"
	    t.integer  "video_source_id"
	    t.boolean  "download_enabled",    :default => false, :null => false
	    t.boolean  "published",           :default => false, :null => false
	    t.datetime "published_at"
	    t.text     "log_text"
	    t.boolean  "recommended",         :default => false, :null => false
	    t.boolean  "deleted",             :default => false, :null => false
	    t.boolean  "embeddable"
      t.timestamps
	  end

	  add_index "videos", ["deleted"], :name => "index_videos_on_deleted"
	  add_index "videos", ["imported_video_id"], :name => "index_videos_on_imported_video_id"
	  add_index "videos", ["permalink"], :name => "index_videos_on_permalink", :unique => true
	  add_index "videos", ["video_source_id"], :name => "index_videos_on_video_source_id"
  end

  def self.down
    drop_table :videos
  end
end
