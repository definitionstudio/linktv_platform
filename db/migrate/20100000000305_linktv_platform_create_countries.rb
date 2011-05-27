class LinktvPlatformCreateCountries < ActiveRecord::Migration
  def self.up
	  create_table "countries", :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci", :force => true do |t|
	    t.string   "name"
	    t.string   "iso3166_1_alpha_2", :limit => 2
	    t.string   "iso3166_1_alpha_3", :limit => 3
	    t.integer  "iso3166_1_numeric"
      t.timestamps
	  end

	  add_index "countries", ["iso3166_1_alpha_2"], :name => "index_countries_on_iso3166_1_alpha_2"
	  add_index "countries", ["iso3166_1_alpha_3"], :name => "index_countries_on_iso3166_1_alpha_3"
	  add_index "countries", ["iso3166_1_numeric"], :name => "index_countries_on_iso3166_1_numeric"
	  add_index "countries", ["name"], :name => "index_countries_on_name"
  end

  def self.down
    drop_table :countries
  end
end
