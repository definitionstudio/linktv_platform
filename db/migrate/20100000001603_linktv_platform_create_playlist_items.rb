class LinktvPlatformCreatePlaylistItems < ActiveRecord::Migration
  def self.up
    create_table :playlist_items, :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" do |t|
      t.integer :playlist_id
      t.integer :display_order
      # 'playlistable_item' is a polymorphic association
	    t.string   :playlistable_item_type, :limit => 40
	    t.integer  :playlistable_item_id
      t.string :comment
      t.string :archive_type
      t.text :archive_data
      t.timestamps
    end

	  add_index :playlist_items, :playlist_id
	  add_index :playlist_items, [:playlist_id, :display_order]
	  add_index :playlist_items, [:playlistable_item_type, :playlistable_item_id]
  end

  def self.down
    drop_table :playlist_items
  end
end
