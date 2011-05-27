class LinktvPlatformCreateRegions < ActiveRecord::Migration
  def self.up
	  create_table "regions", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name"
	    t.string   "code",       :limit => 10
      t.timestamps
	  end

	  add_index "regions", ["code"], :name => "index_regions_on_code", :unique => true
  end

  def self.down
    drop_table :regions
  end
end
