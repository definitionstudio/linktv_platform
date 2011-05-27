class LinktvPlatformCreateGeoRestrictions < ActiveRecord::Migration
  def self.up
	  create_table "geo_restrictions", :id => false, :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.integer  "video_id"
	    t.integer  "country_id"
      t.timestamps
	  end

	  add_index "geo_restrictions", ["country_id"], :name => "index_geo_restrictions_on_country_id"
	  add_index "geo_restrictions", ["video_id", "country_id"], :name => "index_geo_restrictions_on_video_id_and_country_id", :unique => true
	  add_index "geo_restrictions", ["video_id"], :name => "index_geo_restrictions_on_video_id"
  end

  def self.down
    drop_table :geo_restrictions
  end
end
