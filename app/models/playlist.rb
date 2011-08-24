class Playlist < ActiveRecord::Base
  
  has_permalink :name, :scope => :user_id
  
  belongs_to :user
  has_many :playlist_items, :dependent => :destroy

  named_scope :public, :conditions => {:public => true}
  named_scope :ordered, :order => 'display_order ASC, created_at ASC'
  named_scope :include_playlist_items, :include => :playlist_items

  validates_uniqueness_of :name, :scope => :user_id
  validates_length_of :name, :maximum => 40

  def has? item
    PlaylistItem.playlist_id_eq(self.id).
      playlistable_item_type_eq(item.class.name).
      playlistable_item_id_eq(item.id).count > 0
  end

  # Add item to playlist
  def add item
    # Ensure it's not already in the playlist
    return false if playlist_items.scoped_by_playlistable_item_type(item.class.name).scoped_by_playlistable_item_id(item.id).count > 0
    unless item.is_a? PlaylistItem
      item = PlaylistItem.create!(:playlistable_item => item, :playlist_id => self.id)
      item.reload
    end
    playlist_items << item
    true
  end

  # Remove item from playlist
  def remove item
    # Ensure it's not already in the playlist
    return false if playlist_items.scoped_by_playlistable_item_type(item.class.name).scoped_by_playlistable_item_id(item.id).count == 0
    playlist_items.scoped_by_playlistable_item_type(item.class.name).scoped_by_playlistable_item_id(item.id).delete_all
    true
  end

  def << item
    self.add item
  end

  # System reserved names for a user's saved items playlist
  begin
    def self.saved_items_name
      'Saved Items'
    end

    def self.saved_items_permalink
      'saved-items'
    end

    def is_saved_items
      return self.permalink == self.class.saved_items_permalink
    end

    named_scope :saved_items, :conditions => {:permalink => Playlist.saved_items_permalink}
  end

  def before_validation_on_create
  end
  
end




# == Schema Information
#
# Table name: playlists
#
#  id            :integer(4)      not null, primary key
#  name          :string(40)
#  permalink     :string(255)
#  description   :text
#  public        :boolean(1)
#  user_id       :integer(4)
#  display_order :integer(4)
#  created_at    :datetime
#  updated_at    :datetime
#

