class LinktvPlatformCreateImportedVideos < ActiveRecord::Migration
  def self.up
	  create_table "imported_videos", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "video_source_id"
	    t.string   "name",                :limit => 1024
	    t.string   "link",                :limit => 1024
	    t.string   "guid",                :limit => 1024
	    t.text     "xml"
	    t.text     "log_text"
	    t.string   "status"
	    t.integer  "status_by_user_id"
	    t.datetime "status_at"
	    t.datetime "source_published_at"
	    t.text     "notes"
      t.timestamps
	  end

	  add_index "imported_videos", ["status_by_user_id"], :name => "index_imported_videos_on_status_by_user_id"
	  add_index "imported_videos", ["video_source_id"], :name => "index_imported_videos_on_video_source_id"
  end

  def self.down
    drop_table :imported_videos
  end
end
