class LinktvPlatformCreateGeoIpCaches < ActiveRecord::Migration
  def self.up
	  create_table :geo_ip_caches, :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" do |t|
      t.string :ip, :limit => 15
      t.integer :country_id
      t.timestamps
	  end

    add_index :geo_ip_caches, :ip
    add_index :geo_ip_caches, :country_id
  end

  def self.down
    drop_table :geo_ip_caches
  end
end
