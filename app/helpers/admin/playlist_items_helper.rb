module Admin::PlaylistItemsHelper

  def playlist_item_playlistable_item_column record
    link_to record.to_label, polymorphic_path([:admin, record.playlistable_item])
  end

end
