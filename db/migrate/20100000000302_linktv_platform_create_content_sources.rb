class LinktvPlatformCreateContentSources < ActiveRecord::Migration
  def self.up
	  create_table "content_sources", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name"
	    t.text     "description"
	    t.string   "base_url",    :limit => 1024
	    t.boolean  "active",                                                     :default => false, :null => false
	    t.boolean  "deleted",                                                    :default => false, :null => false
	    t.decimal  "weight",                      :precision => 10, :scale => 8, :default => 1.0,   :null => false
	    t.string   "favicon_url", :limit => 1024
      t.timestamps
	  end

	  add_index "content_sources", ["base_url"], :name => "index_content_sources_on_base_url"
  end

  def self.down
    drop_table :content_sources
  end
end
