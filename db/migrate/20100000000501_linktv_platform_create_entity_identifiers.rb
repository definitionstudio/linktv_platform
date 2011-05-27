class LinktvPlatformCreateEntityIdentifiers < ActiveRecord::Migration
  def self.up
	  create_table "entity_identifiers", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "topic_id"
	    t.integer  "entity_db_id"
	    t.string   "identifier",             :limit => 1024
	    t.text     "description"
	    t.text     "data"
	    t.integer  "failed_lookup_attempts",                 :default => 0, :null => false
      t.timestamps
	  end

	  add_index "entity_identifiers", ["entity_db_id"], :name => "index_entity_identifiers_on_entity_db_id"
	  add_index "entity_identifiers", ["identifier"], :name => "index_entity_identifiers_on_identifier"
	  add_index "entity_identifiers", ["topic_id", "entity_db_id"], :name => "index_entity_identifiers_on_topic_id_and_entity_db_id", :unique => true
	  add_index "entity_identifiers", ["topic_id"], :name => "index_entity_identifiers_on_topic_id"
  end

  def self.down
    drop_table :entity_identifiers
  end
end
