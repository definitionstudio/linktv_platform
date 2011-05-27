class LinktvPlatformCreateSemanticApis < ActiveRecord::Migration
  def self.up
	  create_table "semantic_apis", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "type"
	    t.string   "name"
	    t.string   "url",          :limit => 1024
	    t.string   "query_params", :limit => 1024
	    t.string   "quota_config", :limit => 1024
	    t.boolean  "active",                       :default => false, :null => false
	    t.boolean  "deleted",                      :default => false, :null => false
	    t.integer  "lifetime"
      t.timestamps
	  end

	  add_index "semantic_apis", ["active", "deleted", "name"], :name => "index_semantic_apis_on_active_and_deleted_and_name"
  end

  def self.down
    drop_table :semantic_apis
  end
end
