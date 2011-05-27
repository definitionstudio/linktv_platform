class LinktvPlatformCreateLinks < ActiveRecord::Migration
  def self.up
	  create_table "links", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "group",                                            :null => false
	    t.string   "name",                                             :null => false
	    t.integer  "display_order",                 :default => 0,     :null => false
	    t.integer  "page_id"
	    t.string   "url",           :limit => 1024
	    t.boolean  "active",                        :default => false, :null => false
	    t.boolean  "deleted",                       :default => false, :null => false
	    t.string   "target"
      t.timestamps
	  end

	  add_index "links", ["active", "deleted", "group", "display_order"], :name => "index_links_on_active_and_deleted_and_group_and_display_order"
	  add_index "links", ["group", "display_order"], :name => "index_links_on_group_and_display_order"
  end

  def self.down
    drop_table :links
  end
end
