class LinktvPlatformCreateContentTypes < ActiveRecord::Migration
  def self.up
	  create_table "content_types", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name"
	    t.text     "description"
	    t.string   "item_type"
	    t.integer  "display_order", :default => 0,     :null => false
	    t.boolean  "active",        :default => false, :null => false
	    t.boolean  "deleted",       :default => false, :null => false
      t.timestamps
	  end

	  add_index "content_types", ["active", "deleted", "display_order"], :name => "index_content_types_on_active_and_deleted_and_display_order"
	  add_index "content_types", ["display_order"], :name => "index_content_types_on_display_order", :unique => true
  end

  def self.down
    drop_table :content_types
  end
end
