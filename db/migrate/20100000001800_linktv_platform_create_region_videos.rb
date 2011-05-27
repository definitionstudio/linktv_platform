class LinktvPlatformCreateRegionVideos < ActiveRecord::Migration
  def self.up
	  create_table "region_videos", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "region_id"
	    t.integer  "video_id"
      t.timestamps
	  end

	  add_index "region_videos", ["region_id"], :name => "index_region_videos_on_region_id"
	  add_index "region_videos", ["video_id"], :name => "index_region_videos_on_video_id"
  end

  def self.down
    drop_table :region_videos
  end
end
