class LinktvPlatformCreateImages < ActiveRecord::Migration
  def self.up
    create_table :images, :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" do |t|
      t.string :filename
      t.string :has_image_type
      t.integer :has_image_id
      t.string :source_url, :limit => 1024
      t.string :attribution, :limit => 1024
      t.timestamps
    end
    add_index :images, [:has_image_type, :has_image_id]
  end

  def self.down
    drop_table :images
  end
end
