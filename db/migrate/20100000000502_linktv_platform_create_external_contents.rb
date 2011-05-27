class LinktvPlatformCreateExternalContents < ActiveRecord::Migration
  def self.up
	  create_table "external_contents", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name"
	    t.text     "description"
	    t.integer  "display_order"
	    t.string   "url",               :limit => 1024
	    t.text     "data"
	    t.integer  "video_segment_id",                                                                    :null => false
	    t.integer  "content_type_id",                                                                     :null => false
	    t.integer  "semantic_api_id"
	    t.integer  "content_source_id"
	    t.decimal  "score",                             :precision => 10, :scale => 8
	    t.boolean  "sticky",                                                           :default => false, :null => false
	    t.datetime "published_at"
	    t.datetime "expires_at"
	    t.boolean  "active",                                                           :default => false, :null => false
	    t.boolean  "deleted",                                                          :default => false, :null => false
	    t.integer  "video_id",                                                                            :null => false
	    t.string   "identifier",        :limit => 1024
	    t.integer  "duration"
      t.timestamps
	  end

	  add_index "external_contents", ["active", "deleted", "video_segment_id"], :name => "idx_extcont_on_live_n__video_seg_id"
	  add_index "external_contents", ["content_source_id"], :name => "index_external_contents_on_content_source_id"
	  add_index "external_contents", ["identifier"], :name => "index_external_contents_on_identifier"
	  add_index "external_contents", ["semantic_api_id"], :name => "index_external_contents_on_semantic_api_id"
	  add_index "external_contents", ["video_id"], :name => "index_external_contents_on_video_id"
	  add_index "external_contents", ["video_segment_id"], :name => "index_external_contents_on_video_segment_id"
    add_index :external_contents, [:video_segment_id, :display_order]
  end

  def self.down
    drop_table :external_contents
  end
end
