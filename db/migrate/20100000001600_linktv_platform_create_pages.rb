class LinktvPlatformCreatePages < ActiveRecord::Migration
  def self.up
	  create_table "pages", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name",                          :null => false
	    t.string   "path",                          :null => true
	    t.text     "content",                       :null => false
	    t.boolean  "active",     :default => false, :null => false
	    t.boolean  "deleted",    :default => false, :null => false
      t.timestamps
	  end

	  add_index "pages", ["active", "deleted", "path"], :name => "index_pages_on_active_and_deleted_and_path"
	  add_index "pages", ["path"], :name => "index_pages_on_path", :unique => true
  end

  def self.down
    drop_table :pages
  end
end
