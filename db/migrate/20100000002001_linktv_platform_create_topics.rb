class LinktvPlatformCreateTopics < ActiveRecord::Migration
  def self.up
	  create_table "topics", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name"
	    t.string   "sort_name"
	    t.string   "category"
	    t.text     "description"
	    t.boolean  "active",      :default => false, :null => false
	    t.boolean  "deleted",     :default => false, :null => false
	    t.string   "guid"
	    t.string   "permalink"
      t.timestamps
	  end

	  add_index "topics", ["active", "deleted"], :name => "index_topics_on_active_and_deleted"
	  add_index "topics", ["guid"], :name => "index_topics_on_guid", :unique => true
	  add_index "topics", ["name"], :name => "index_topics_on_name"
	  add_index "topics", ["permalink"], :name => "index_topics_on_permalink", :unique => true
    add_index :topics, :sort_name
  end

  def self.down
    drop_table :topics
  end
end
