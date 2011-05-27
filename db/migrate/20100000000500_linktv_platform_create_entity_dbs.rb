class LinktvPlatformCreateEntityDbs < ActiveRecord::Migration
  def self.up
	  create_table "entity_dbs", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "type"
	    t.string   "name"
	    t.text     "description"
	    t.string   "url",              :limit => 1024
	    t.string   "icon_css_class"
	    t.string   "identifier_regex"
	    t.boolean  "active",                           :default => false, :null => false
	    t.boolean  "deleted",                          :default => false, :null => false
      t.timestamps
	  end

	  add_index "entity_dbs", ["active", "deleted", "name"], :name => "index_entity_dbs_on_active_and_deleted_and_name"
	  add_index "entity_dbs", ["name"], :name => "index_entity_dbs_on_name"
  end

  def self.down
    drop_table :entity_dbs
  end
end
