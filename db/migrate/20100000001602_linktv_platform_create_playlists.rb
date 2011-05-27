class LinktvPlatformCreatePlaylists < ActiveRecord::Migration
  def self.up
    create_table :playlists, :options => "ENGINE=InnoDB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci"  do |t|
      t.string :name, :limit => 40 # Not unique
      t.string :permalink
      t.text :description
      t.boolean :public
      t.integer :user_id, :null => true
      t.integer :display_order
      t.timestamps
    end

    add_index :playlists, [:user_id, :display_order]
    add_index :playlists, [:user_id, :display_order, :public]
    add_index :playlists, [:user_id, :name], :unique => true
    add_index :playlists, [:user_id, :permalink], :unique => true
  end

  def self.down
    drop_table :playlists
  end
end
