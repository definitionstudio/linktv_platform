class LinktvPlatformCreateVideoFiles < ActiveRecord::Migration
  def self.up
	  create_table "video_files", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "video_id"
	    t.string   "url",        :limit => 1024
	    t.string   "cdn_path",   :limit => 1024
	    t.string   "media_type", :limit => 40
	    t.integer  "file_size"
	    t.string   "mime_type"
	    t.integer  "bitrate"
	    t.string   "status"
	    t.boolean  "active",                     :default => false, :null => false
	    t.boolean  "deleted",                    :default => false, :null => false
      t.timestamps
	  end

	  add_index "video_files", ["active", "deleted"], :media_instance_type => "index_video_files_on_active_and_deleted"
	  add_index "video_files", ["video_id"], :media_instance_type => "index_video_files_on_video_id"
    add_index :video_files, [:active, :deleted, :video_id, :media_type]
    add_index :video_files, [:active, :deleted, :status, :video_id, :media_type, :created_at]
  end

  def self.down
    drop_table :video_files
  end
end
