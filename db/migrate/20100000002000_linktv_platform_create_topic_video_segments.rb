class LinktvPlatformCreateTopicVideoSegments < ActiveRecord::Migration
  def self.up
	  create_table "topic_video_segments", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "topic_id"
	    t.integer  "video_segment_id"
	    t.integer  "semantic_api_id"
	    t.integer  "score"
	    t.integer  "video_id"
      t.timestamps
	  end

	  add_index "topic_video_segments", ["semantic_api_id"], :name => "index_topic_video_segments_on_semantic_api_id"
	  add_index "topic_video_segments", ["topic_id"], :name => "index_topic_video_segments_on_topic_id"
	  add_index "topic_video_segments", ["video_id"], :name => "index_topic_video_segments_on_video_id"
	  add_index "topic_video_segments", ["video_segment_id"], :name => "index_topic_video_segments_on_video_segment_id"
  end

  def self.down
    drop_table :topic_video_segments
  end
end
