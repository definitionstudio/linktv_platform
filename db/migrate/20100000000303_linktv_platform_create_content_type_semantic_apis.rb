class LinktvPlatformCreateContentTypeSemanticApis < ActiveRecord::Migration
  def self.up
	  create_table "content_type_semantic_apis", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "semantic_api_id"
	    t.integer  "content_type_id"
      t.timestamps
	  end

	  add_index "content_type_semantic_apis", ["content_type_id"], :name => "index_content_type_semantic_apis_on_content_type_id"
	  add_index "content_type_semantic_apis", ["semantic_api_id"], :name => "index_content_type_semantic_apis_on_semantic_api_id"
  end

  def self.down
    drop_table :content_type_semantic_apis
  end
end
