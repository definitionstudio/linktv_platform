class LinktvPlatformCreateResourceAttrs < ActiveRecord::Migration
  def self.up
	  create_table "resource_attrs", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "resource_id"
	    t.string   "resource_type", :limit => 40
	    t.string   "name",          :limit => 40
	    t.text     "value"
      t.timestamps
	  end

	  add_index "resource_attrs", ["resource_id", "resource_type", "name"], :name => "index_resource_attrs_on_resource_id_and_resource_type_and_name"
	  add_index "resource_attrs", ["resource_id", "resource_type"], :name => "index_resource_attrs_on_resource_id_and_resource_type"
  end

  def self.down
    drop_table :resource_attrs
  end
end
