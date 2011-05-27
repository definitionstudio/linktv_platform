class LinktvPlatformCreateVideoSegments < ActiveRecord::Migration
  def self.up
	  create_table "video_segments", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "temp_tag"
	    t.string   "name"
	    t.integer  "video_id"
	    t.integer  "start_time"
	    t.text     "transcript_text"
	    t.boolean  "active",                  :default => false, :null => false
	    t.boolean  "deleted",                 :default => false, :null => false
	    t.boolean  "external_update_pending", :default => false, :null => false
      t.timestamps
	  end

	  add_index "video_segments", ["active", "deleted", "video_id", "start_time"], :name => "idx_vidseg_live_vid_id_start_time"
	  add_index "video_segments", ["video_id", "start_time"], :name => "index_video_segments_on_video_id_and_start_time"
	  add_index "video_segments", ["video_id"], :name => "index_video_segments_on_video_id"
  end

  def self.down
    drop_table :video_segments
  end
end
